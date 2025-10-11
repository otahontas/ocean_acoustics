%% C-Linear Ray Tracer
% Reads scenario.env and traces rays using discretized c-linear method

clear; close all; clc;

%% Read scenario and setup
scenario = read_scenario('scenario.env');

% Constants
KM_TO_M = 1000;

% Physics: Create function handles for sound speed and its gradient
DZ_FINITE_DIFF = 0.1; % Step for finite difference gradient calculation
c_of_z = @(z) interp1(scenario.ssp_z, scenario.ssp_c, z, 'linear', 'extrap');
dc_dz = @(z) (c_of_z(z+DZ_FINITE_DIFF) - c_of_z(z-DZ_FINITE_DIFF)) / (2*DZ_FINITE_DIFF);

% Eigenray tracing parameters
N_BEAMS = 1001;                     % Number of beams to trace for eigenrays
MAX_RANGE_FACTOR = 1.2;             % Trace up to 1.2x the receiver range
MAX_STEPS = 5e6;                    % Safety break for ray tracing loop
DEPTH_TOLERANCE = 10;               % Tolerance for eigenray depth match (m)
INTERPOLATION_TOLERANCE = 1e-12;    % Tolerance for range interpolation
STOP_TRACE_AFTER_TARGET_M = 1000;   % Stop tracing 1km after receiver range

% Generate launch angles
angles = deg2rad(linspace(scenario.angle_min, scenario.angle_max, N_BEAMS));
max_range = scenario.r_rec * MAX_RANGE_FACTOR;

% Plotting parameters
N_FAN_BEAMS = 101;                  % Number of beams for the display fan
FAN_ANGLE_MIN = -30;                % Min angle for the fan
FAN_ANGLE_MAX = 30;                 % Max angle for the fan
MAX_PLOT_STEPS = 5000;              % Max steps for plotting a single ray
PLOT_RANGE_FACTOR = 1.05;           % Plot up to 1.05x the receiver range
MAX_DEPTH_PLOT = 10000;             % Safety break for depth in plots
FAN_COLOR = [0.8 0.8 0.8];          % Color of the ray fan
EIGENRAY_LINE_WIDTH = 2;            % Line width for eigenrays
BOUNDARY_RECT_HEIGHT = 500;         % Height of boundary rectangles in plot
SOURCE_MARKER_SIZE = 10;
RECEIVER_MARKER_SIZE = 8;
YLIM_PADDING_TOP = 200;
YLIM_PADDING_BOTTOM = 400;


%% Trace eigenrays
% Loop through each launch angle to find rays that hit the receiver

eigenrays = {};

for angle_idx = 1:length(angles)
    % Initialize ray state
    theta = angles(angle_idx);
    x = 0; z = scenario.z_s; t = 0;

    % Pre-allocate path arrays for speed
    est_size = min(ceil(max_range/scenario.ds)*3, MAX_STEPS);
    rpath = zeros(1, est_size);
    zpath = zeros(1, est_size);
    tpath = zeros(1, est_size);
    rpath(1) = x; zpath(1) = z; tpath(1) = t;
    path_idx = 1;

    step = 0;
    found = false;
    last_finite_idx = 1;
    second_last_finite_idx = 0;

    % Main ray tracing loop
    while x <= max_range && step < MAX_STEPS
        step = step + 1;

        % C-linear method: Update ray angle and position
        c_curr = c_of_z(z);
        g_local = dc_dz(z);
        kappa1 = -(g_local * cos(theta)) / c_curr; % Curvature

        theta_new = theta + scenario.ds * kappa1;
        x_new = x + scenario.ds * cos(theta);
        z_new = z + scenario.ds * sin(theta);
        t_new = t + scenario.ds / c_curr;

        % Boundary reflection logic
        if (z_new < scenario.z_min) || (z_new > scenario.z_max)
            % Interpolate to find hit point
            if z_new < scenario.z_min
                alpha = (scenario.z_min - z) / (z_new - z);
                z_hit = scenario.z_min;
            else
                alpha = (scenario.z_max - z) / (z_new - z);
                z_hit = scenario.z_max;
            end
            alpha = max(0,min(1,alpha)); % Clamp alpha to [0,1]

            x_hit = x + alpha * (x_new - x);
            t_hit = t + alpha * (t_new - t);

            % Store hit point and a NaN to break the line in plots
            path_idx = path_idx + 1; rpath(path_idx) = x_hit; zpath(path_idx) = z_hit; tpath(path_idx) = t_hit;
            second_last_finite_idx = last_finite_idx;
            last_finite_idx = path_idx;
            path_idx = path_idx + 1; rpath(path_idx) = NaN; zpath(path_idx) = NaN; tpath(path_idx) = NaN;

            % Reflect angle
            theta = -theta;

            % Continue with remaining step distance
            ds_rem = scenario.ds * (1 - alpha);
            if ds_rem > 0
                x = x_hit + ds_rem * cos(theta);
                z = z_hit + ds_rem * sin(theta);
                c_at_hit = c_of_z(z_hit);
                t = t_hit + ds_rem / c_at_hit;
                path_idx = path_idx + 1; rpath(path_idx) = x; zpath(path_idx) = z; tpath(path_idx) = t;
                second_last_finite_idx = last_finite_idx;
                last_finite_idx = path_idx;
            else
                x = x_hit; z = z_hit; t = t_hit;
            end
        else
            % No reflection, update state normally
            x = x_new; z = z_new; theta = theta_new; t = t_new;
            path_idx = path_idx + 1; rpath(path_idx) = x; zpath(path_idx) = z; tpath(path_idx) = t;
            second_last_finite_idx = last_finite_idx;
            last_finite_idx = path_idx;
        end

        % Check for eigenray (passing receiver range at correct depth)
        if second_last_finite_idx > 0 && ~found
            idx1 = second_last_finite_idx;
            idx2 = last_finite_idx;
            r_start = rpath(idx1); z_start = zpath(idx1); t_start = tpath(idx1);
            r_end = rpath(idx2); z_end = zpath(idx2); t_end = tpath(idx2);

            % Check if the last segment crossed the receiver range
            if ( (r_start <= scenario.r_rec && r_end >= scenario.r_rec) || (r_start >= scenario.r_rec && r_end <= scenario.r_rec) ) && abs(r_end-r_start) > INTERPOLATION_TOLERANCE
                % Interpolate to find depth at receiver range
                alpha = (scenario.r_rec - r_start) / (r_end - r_start);
                z_at_r = z_start + alpha*(z_end - z_start);
                t_at_r = t_start + alpha*(t_end - t_start);

                if abs(z_at_r - scenario.z_rec) <= DEPTH_TOLERANCE
                    % Found an eigenray, store it and stop tracing this beam
                    entry.theta0 = angles(angle_idx);
                    entry.rpath = rpath(1:path_idx);
                    entry.zpath = zpath(1:path_idx);
                    entry.tt = tpath(1:path_idx);
                    entry.z_at_r = z_at_r;
                    entry.t_at_r = t_at_r;
                    eigenrays{end+1} = entry;
                    found = true;
                    break;
                end
            end
        end

        % Optimization: stop if ray is well past the receiver
        if x > scenario.r_rec + STOP_TRACE_AFTER_TARGET_M, break; end
    end
end

%% Plot results
plot_results(scenario, eigenrays, c_of_z, dc_dz);
