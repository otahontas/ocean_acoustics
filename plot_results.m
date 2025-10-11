function plot_results(scenario, eigenrays, c_of_z, dc_dz)
% PLOT_RESULTS Plots the ray fan and eigenrays.
%   PLOT_RESULTS(scenario, eigenrays, c_of_z, dc_dz) generates a plot
%   of the ray tracing results.

KM_TO_M = 1000;

% Plotting parameters
N_FAN_BEAMS = 101;                  % Number of beams for the display fan
FAN_ANGLE_MIN = -30;                % Min angle for the fan
FAN_ANGLE_MAX = 30;                 % Max angle for the fan
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
    [r_plot, z_plot, ~] = trace_ray(plot_angle, scenario, c_of_z, dc_dz);
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
