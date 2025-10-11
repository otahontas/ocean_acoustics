function [rpath, zpath, tpath] = trace_ray(start_angle, scenario, c_of_z, dc_dz)
% TRACE_RAY Traces a single ray using the c-linear method.
%   [rpath, zpath, tpath] = TRACE_RAY(start_angle, scenario, c_of_z, dc_dz)
%   traces a ray with a given starting angle and returns its path.

MAX_RANGE_FACTOR = 1.2;
MAX_STEPS = 5e6;

max_range = scenario.r_rec * MAX_RANGE_FACTOR;

% Initialize ray state
theta = start_angle;
x = 0; z = scenario.z_s; t = 0;

% Pre-allocate path arrays for speed
est_size = min(ceil(max_range/scenario.ds)*3, MAX_STEPS);
rpath = zeros(1, est_size);
zpath = zeros(1, est_size);
tpath = zeros(1, est_size);
rpath(1) = x; zpath(1) = z; tpath(1) = t;
path_idx = 1;

step = 0;

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
        else
            x = x_hit; z = z_hit; t = t_hit;
        end
    else
        % No reflection, update state normally
        x = x_new; z = z_new; theta = theta_new; t = t_new;
        path_idx = path_idx + 1; rpath(path_idx) = x; zpath(path_idx) = z; tpath(path_idx) = t;
    end

    % Optimization: stop if ray is well past the receiver
    if x > scenario.r_rec + 1000, break; end
end

% Trim unused allocated memory
rpath = rpath(1:path_idx);
zpath = zpath(1:path_idx);
tpath = tpath(1:path_idx);

end
