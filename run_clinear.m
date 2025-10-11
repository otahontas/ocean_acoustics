%% C-Linear Ray Tracer
% Reads scenario.env and traces rays using discretized c-linear method

clear; close all; clc;

%% Read scenario.env
% This section parses the Bellhop-style environment file.

fid = fopen('scenario.env', 'r');

% Skip file header
fgetl(fid); fgetl(fid); fgetl(fid); fgetl(fid);

% Read Sound Speed Profile (SSP)
line = strsplit(strtrim(fgetl(fid)));
n_ssp = str2double(line{1});
z_min = str2double(line{2}); % Top boundary
z_max = str2double(line{3}); % Bottom boundary

ssp_z = zeros(n_ssp, 1);
ssp_c = zeros(n_ssp, 1);
for i = 1:n_ssp
    line = strsplit(strtrim(fgetl(fid)));
    ssp_z(i) = str2double(line{1});
    ssp_c(i) = str2double(line{2});
end

% Skip boundary condition lines
fgetl(fid); fgetl(fid);

% Read source and receiver geometry
fgetl(fid); % skip source count
line = strsplit(strtrim(fgetl(fid)));
z_s = str2double(line{1}); % Source depth

fgetl(fid); % skip receiver depth count
line = strsplit(strtrim(fgetl(fid)));
z_rec = str2double(line{1}); % Receiver depth

fgetl(fid); % skip receiver range count
line = strsplit(strtrim(fgetl(fid)));
r_rec = str2double(line{1}) * 1000; % Receiver range (km to m)

% Read beam parameters
fgetl(fid); fgetl(fid); % skip beam type and count
line = strsplit(strtrim(fgetl(fid)));
angle_min = str2double(line{1}); % Minimum launch angle
angle_max = str2double(line{2}); % Maximum launch angle

line = strsplit(strtrim(fgetl(fid)));
ds = str2double(line{1}); % Step size (m)

fclose(fid);

%% Setup

% Constants
KM_TO_M = 1000;

% Physics: Create function handles for sound speed and its gradient
DZ_FINITE_DIFF = 0.1; % Step for finite difference gradient calculation
c_of_z = @(z) interp1(ssp_z, ssp_c, z, 'linear', 'extrap');
dc_dz = @(z) (c_of_z(z+DZ_FINITE_DIFF) - c_of_z(z-DZ_FINITE_DIFF)) / (2*DZ_FINITE_DIFF);

% Eigenray tracing parameters
N_BEAMS = 1001;                     % Number of beams to trace for eigenrays
MAX_RANGE_FACTOR = 1.2;             % Trace up to 1.2x the receiver range
MAX_STEPS = 5e6;                    % Safety break for ray tracing loop
DEPTH_TOLERANCE = 10;               % Tolerance for eigenray depth match (m)
INTERPOLATION_TOLERANCE = 1e-12;    % Tolerance for range interpolation
STOP_TRACE_AFTER_TARGET_M = 1000;   % Stop tracing 1km after receiver range

% Generate launch angles
angles = deg2rad(linspace(angle_min, angle_max, N_BEAMS));
max_range = r_rec * MAX_RANGE_FACTOR;

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
    x = 0; z = z_s; t = 0;

    % Pre-allocate path arrays for speed
    est_size = min(ceil(max_range/ds)*3, MAX_STEPS);
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

        theta_new = theta + ds * kappa1;
        x_new = x + ds * cos(theta);
        z_new = z + ds * sin(theta);
        t_new = t + ds / c_curr;

        % Boundary reflection logic
        if (z_new < z_min) || (z_new > z_max)
            % Interpolate to find hit point
            if z_new < z_min
                alpha = (z_min - z) / (z_new - z);
                z_hit = z_min;
            else
                alpha = (z_max - z) / (z_new - z);
                z_hit = z_max;
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
            ds_rem = ds * (1 - alpha);
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
            if ( (r_start <= r_rec && r_end >= r_rec) || (r_start >= r_rec && r_end <= r_rec) ) && abs(r_end-r_start) > INTERPOLATION_TOLERANCE
                % Interpolate to find depth at receiver range
                alpha = (r_rec - r_start) / (r_end - r_start);
                z_at_r = z_start + alpha*(z_end - z_start);
                t_at_r = t_start + alpha*(t_end - t_start);

                if abs(z_at_r - z_rec) <= DEPTH_TOLERANCE
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
        if x > r_rec + STOP_TRACE_AFTER_TARGET_M, break; end
    end
end

%% Plot
figure('Color','w','Position',[200 200 1000 600]);
hold on; box on;

% Plot ray fan for visualization
angles_plot = linspace(FAN_ANGLE_MIN, FAN_ANGLE_MAX, N_FAN_BEAMS);
for plot_angle_idx = 1:length(angles_plot)
    plot_angle = deg2rad(angles_plot(plot_angle_idx));
    theta = plot_angle; x = 0; z = z_s;
    r_plot = x; z_plot = z;

    for plot_step_idx = 1:MAX_PLOT_STEPS
        % Stop if ray goes too far or too deep
        if x > r_rec*PLOT_RANGE_FACTOR || z < 0 || z > MAX_DEPTH_PLOT, break; end

        % Simplified ray tracing for plotting (no travel time needed)
        c_curr = c_of_z(z);
        g_local = dc_dz(z);
        kappa = -(g_local * cos(theta)) / c_curr;
        theta_new = theta + ds * kappa;
        x_new = x + ( sin(theta_new) - sin(theta) ) / kappa;
        z_new = z + ( cos(theta) - cos(theta_new) ) / kappa;

        % Boundary reflection
        if (z_new < z_min) || (z_new > z_max)
            if z_new < z_min
                alpha = (z_min - z) / (z_new - z);
                z_hit = z_min;
            else
                alpha = (z_max - z) / (z_new - z);
                z_hit = z_max;
            end
            alpha = max(0,min(1,alpha));
            x_hit = x + alpha * (x_new - x);
            r_plot(end+1) = x_hit; z_plot(end+1) = z_hit;
            r_plot(end+1) = NaN; z_plot(end+1) = NaN; % Break line
            theta = -theta; % Reflect

            ds_rem = ds * (1 - alpha);
            if ds_rem > 0
                x = x_hit + ds_rem * cos(theta);
                z = z_hit + ds_rem * sin(theta);
                r_plot(end+1) = x; z_plot(end+1) = z;
            else
                x = x_hit; z = z_hit;
            end
        else
            theta = theta_new;
            x = x_new; z = z_new;
            r_plot(end+1) = x; z_plot(end+1) = z;
        end
    end
    plot(r_plot/KM_TO_M, z_plot, 'Color', FAN_COLOR);
end

% Plot detected eigenrays
for eigenray_idx = 1:length(eigenrays)
    eigenray = eigenrays{eigenray_idx};
    er_z = eigenray.zpath;
    er_z(er_z < z_min) = z_min; % Clamp to boundaries for plotting
    er_z(er_z > z_max) = z_max;
    plot(eigenray.rpath/KM_TO_M, er_z, 'LineWidth', EIGENRAY_LINE_WIDTH);
    plot(r_rec/KM_TO_M, eigenray.z_at_r, 'ro', 'MarkerFaceColor','r');
end

% Plot ocean boundaries
rectangle('Position',[0 z_max r_rec/KM_TO_M z_max+BOUNDARY_RECT_HEIGHT], ...
         'FaceColor',[0.6 0.3 0],'EdgeColor','black','LineWidth', 1);
rectangle('Position',[0 (-BOUNDARY_RECT_HEIGHT) r_rec/KM_TO_M BOUNDARY_RECT_HEIGHT], ...
        'FaceColor',[0.5 0.7 1], 'EdgeColor','blue','LineWidth',1);

% Plot source and receiver positions
plot(0, z_s, 'kp', 'MarkerFaceColor','k', 'MarkerSize', SOURCE_MARKER_SIZE);
plot(r_rec/KM_TO_M, z_rec, 'mo', 'MarkerFaceColor','m', 'MarkerSize', RECEIVER_MARKER_SIZE);

% Final plot adjustments
xlabel('Range (km)');
ylabel('Depth (m)');
set(gca,'YDir','reverse');
title(sprintf('C-Linear: %d eigenrays', length(eigenrays)));
xlim([0 r_rec/KM_TO_M]);
ylim([z_min - YLIM_PADDING_TOP z_max+YLIM_PADDING_BOTTOM]);
grid on;
