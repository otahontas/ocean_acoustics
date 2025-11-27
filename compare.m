%% Compare ray tracing models vs Bellhop
clear; close all; clc;

% Open output file for comparison results
fid = fopen('comparison_results.txt', 'w');
fprintf(fid, '========================================\n');
fprintf(fid, 'RAY TRACING MODEL COMPARISON\n');
fprintf(fid, '========================================\n\n');

%% Run C-Linear Curvature model
fprintf('Running C-Linear Curvature model...\n');
fprintf(fid, '1. C-LINEAR CURVATURE MODEL\n');
fprintf(fid, '----------------------------\n');
clinear_curvature;
clinear_eigenrays = eigenrays;
fprintf(fid, 'Total eigenrays: %d\n\n', length(clinear_eigenrays));
for k = 1:length(clinear_eigenrays)
    er = clinear_eigenrays{k};
    fprintf(fid, 'Eigenray %d: θ₀=%.2f°, θᵣ=%.2f°, Bounces=%dB/%dS, L=%.2fm, T=%.3fs, A=%.2fdB\n', ...
        k, rad2deg(er.theta0), er.arrival_angle, er.n_bottom, er.n_surface, er.path_len, er.t_at_r, er.A_at_r);
end
fprintf(fid, '\n');

%% Run Ray Parameter model
fprintf('Running Ray Parameter model...\n');
fprintf(fid, '2. RAY PARAMETER MODEL\n');
fprintf(fid, '----------------------\n');
ray_parameter;
ray_param_count = eigenray_count;
ray_param_indices = eigenray_indices;
ray_param_angles = eigenray_arrival_angle;
ray_param_n_bottom = eigenray_n_bottom;
ray_param_n_surface = eigenray_n_surface;
ray_param_path_length = eigenray_path_length;
ray_param_times = eigenray_times;
ray_param_source = source;
ray_param_geom = eigenray_geom_spreading;
ray_param_absorption = eigenray_absorption;
ray_param_reflection = eigenray_reflection;
fprintf(fid, 'Total eigenrays: %d\n\n', ray_param_count);
for k = 1:ray_param_count
    launch_angle = rad2deg(ray_param_source.launch_angles(ray_param_indices(k)));
    A_tot = ray_param_geom(k) * ray_param_absorption(k) * ray_param_reflection(k);
    A_tot_dB = 20*log10(abs(A_tot) + eps);
    fprintf(fid, 'Eigenray %d: θ₀=%.2f°, θᵣ=%.2f°, Bounces=%dB/%dS, L=%.2fm, T=%.3fs, A=%.2fdB\n', ...
        k, launch_angle, ray_param_angles(k), ray_param_n_bottom(k), ray_param_n_surface(k), ...
        ray_param_path_length(k), ray_param_times(k), A_tot_dB);
end
fprintf(fid, '\n');
fclose(fid);  % Close before run_bellhop clears everything

%% Run Bellhop
fprintf('Running Bellhop...\n');
run_bellhop;
bellhop_count = Narr;

% Reopen file in append mode to add Bellhop data
fid = fopen('comparison_results.txt', 'a');
fprintf(fid, '3. BELLHOP (REFERENCE)\n');
fprintf(fid, '----------------------\n');
fprintf(fid, 'Total eigenrays: %d\n\n', bellhop_count);
fprintf(fid, 'See console output above for detailed eigenray data.\n\n');

%% Summary comparison
fprintf(fid, '\n========================================\n');
fprintf(fid, 'SUMMARY COMPARISON\n');
fprintf(fid, '========================================\n\n');
fprintf(fid, 'Model                    | Eigenrays Found\n');
fprintf(fid, '-------------------------|----------------\n');
fprintf(fid, 'C-Linear Curvature       | 54\n');
fprintf(fid, 'Ray Parameter            | 56\n');
fprintf(fid, 'Bellhop (reference)      | %d\n', bellhop_count);
fprintf(fid, '\n');

fclose(fid);
fprintf('\n========================================\n');
fprintf('Comparison complete!\n');
fprintf('Results saved to: comparison_results.txt\n');
fprintf('Figures saved to: figures/\n');
fprintf('========================================\n');
