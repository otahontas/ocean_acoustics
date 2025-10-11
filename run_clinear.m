%% C-Linear Ray Tracer
% Reads scenario.env and traces rays using discretized c-linear method

clear; close all; clc;

%% Read scenario and setup
scenario = read_scenario('scenario.env');

% Physics: Create function handles for sound speed and its gradient
DZ_FINITE_DIFF = 0.1; % Step for finite difference gradient calculation
c_of_z = @(z) interp1(scenario.ssp_z, scenario.ssp_c, z, 'linear', 'extrap');
dc_dz = @(z) (c_of_z(z+DZ_FINITE_DIFF) - c_of_z(z-DZ_FINITE_DIFF)) / (2*DZ_FINITE_DIFF);

% Eigenray tracing parameters
N_BEAMS = 1001;                     % Number of beams to trace for eigenrays
DEPTH_TOLERANCE = 10;               % Tolerance for eigenray depth match (m)
INTERPOLATION_TOLERANCE = 1e-12;    % Tolerance for range interpolation

% Generate launch angles
angles = deg2rad(linspace(scenario.angle_min, scenario.angle_max, N_BEAMS));


%% Trace eigenrays
% Loop through each launch angle to find rays that hit the receiver

eigenrays = {};

for angle_idx = 1:length(angles)
    path = trace_ray(angles(angle_idx), scenario, c_of_z, dc_dz);

    % Check for eigenray (passing receiver range at correct depth)
    for i = 1:length(path.r)-1
        if isnan(path.r(i)) || isnan(path.r(i+1))
            continue;
        end

        r_start = path.r(i); z_start = path.z(i); t_start = path.t(i);
        r_end = path.r(i+1); z_end = path.z(i+1); t_end = path.t(i+1);

        % Check if the last segment crossed the receiver range
        if ( (r_start <= scenario.r_rec && r_end >= scenario.r_rec) || (r_start >= scenario.r_rec && r_end <= scenario.r_rec) ) && abs(r_end-r_start) > INTERPOLATION_TOLERANCE
            % Interpolate to find depth at receiver range
            alpha = (scenario.r_rec - r_start) / (r_end - r_start);
            z_at_r = z_start + alpha*(z_end - z_start);
            t_at_r = t_start + alpha*(t_end - t_start);

            if abs(z_at_r - scenario.z_rec) <= DEPTH_TOLERANCE
                % Found an eigenray, store it and stop tracing this beam
                entry.theta0 = angles(angle_idx);
                entry.path = path;
                entry.z_at_r = z_at_r;
                entry.t_at_r = t_at_r;
                eigenrays{end+1} = entry;
                break; % Move to next angle
            end
        end
    end
end

%% Plot results
plot_results(scenario, eigenrays, c_of_z, dc_dz);
