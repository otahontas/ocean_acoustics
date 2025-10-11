function plot_results(scenario, eigenrays, c_of_z, dc_dz)
% PLOT_RESULTS Plots the ray fan and eigenrays.
%   PLOT_RESULTS(scenario, eigenrays, c_of_z, dc_dz) generates a plot
%   of the ray tracing results.

KM_TO_M = 1000;

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

figure('Color','w','Position',[200 200 1000 600]);
hold on; box on;

% Plot ray fan for visualization
angles_plot = linspace(FAN_ANGLE_MIN, FAN_ANGLE_MAX, N_FAN_BEAMS);
for plot_angle_idx = 1:length(angles_plot)
    plot_angle = deg2rad(angles_plot(plot_angle_idx));
    theta = plot_angle; x = 0; z = scenario.z_s;
    r_plot = x; z_plot = z;

    for plot_step_idx = 1:MAX_PLOT_STEPS
        % Stop if ray goes too far or too deep
        if x > scenario.r_rec*PLOT_RANGE_FACTOR || z < 0 || z > MAX_DEPTH_PLOT, break; end

        % Simplified ray tracing for plotting (no travel time needed)
        c_curr = c_of_z(z);
        g_local = dc_dz(z);
        kappa = -(g_local * cos(theta)) / c_curr;
        theta_new = theta + scenario.ds * kappa;
        x_new = x + ( sin(theta_new) - sin(theta) ) / kappa;
        z_new = z + ( cos(theta) - cos(theta_new) ) / kappa;

        % Boundary reflection
        if (z_new < scenario.z_min) || (z_new > scenario.z_max)
            if z_new < scenario.z_min
                alpha = (scenario.z_min - z) / (z_new - z);
                z_hit = scenario.z_min;
            else
                alpha = (scenario.z_max - z) / (z_new - z);
                z_hit = scenario.z_max;
            end
            alpha = max(0,min(1,alpha));
            x_hit = x + alpha * (x_new - x);
            r_plot(end+1) = x_hit; z_plot(end+1) = z_hit;
            r_plot(end+1) = NaN; z_plot(end+1) = NaN; % Break line
            theta = -theta; % Reflect

            ds_rem = scenario.ds * (1 - alpha);
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
    er_z(er_z < scenario.z_min) = scenario.z_min; % Clamp to boundaries for plotting
    er_z(er_z > scenario.z_max) = scenario.z_max;
    plot(eigenray.rpath/KM_TO_M, er_z, 'LineWidth', EIGENRAY_LINE_WIDTH);
    plot(scenario.r_rec/KM_TO_M, eigenray.z_at_r, 'ro', 'MarkerFaceColor','r');
end

% Plot ocean boundaries
rectangle('Position',[0 scenario.z_max scenario.r_rec/KM_TO_M scenario.z_max+BOUNDARY_RECT_HEIGHT], ...
         'FaceColor',[0.6 0.3 0],'EdgeColor','black','LineWidth', 1);
rectangle('Position',[0 (-BOUNDARY_RECT_HEIGHT) scenario.r_rec/KM_TO_M BOUNDARY_RECT_HEIGHT], ...
        'FaceColor',[0.5 0.7 1], 'EdgeColor','blue','LineWidth',1);

% Plot source and receiver positions
plot(0, scenario.z_s, 'kp', 'MarkerFaceColor','k', 'MarkerSize', SOURCE_MARKER_SIZE);
plot(scenario.r_rec/KM_TO_M, scenario.z_rec, 'mo', 'MarkerFaceColor','m', 'MarkerSize', RECEIVER_MARKER_SIZE);

% Final plot adjustments
xlabel('Range (km)');
ylabel('Depth (m)');
set(gca,'YDir','reverse');
title(sprintf('C-Linear: %d eigenrays', length(eigenrays)));
xlim([0 scenario.r_rec/KM_TO_M]);
ylim([scenario.z_min - YLIM_PADDING_TOP scenario.z_max+YLIM_PADDING_BOTTOM]);
grid on;

end
