%% Master Comparison Script
% Generates all comparison plots and metrics for paper
clear; close all; clc;

% Add utils to path
% Note: When run via matlab -batch, use pwd; when run directly, mfilename works
if isempty(regexp(mfilename, '^LiveEditorEvaluationHelper'))
    script_dir = fileparts(mfilename('fullpath'));
else
    script_dir = pwd;
end
if isempty(script_dir)
    script_dir = pwd;  % Fallback to current directory
end
utils_path = fullfile(script_dir, 'utils');
addpath(utils_path);

fprintf('=== OCEAN ACOUSTICS MODEL COMPARISON ===\n\n');

%% Step 1: Run all models and extract data

fprintf('Step 1: Running models and extracting eigenrays...\n');

% Run clinear_curvature
fprintf('  Running clinear_curvature...\n');
run('clinear_curvature.m');
params_clin.z_s = 1000; params_clin.r_s = 0;
params_clin.z_rec = 1000; params_clin.r_rec = 100000; params_clin.f = 50;
data_clinear = extract_eigenrays_clinear(eigenrays, params_clin);
close all; % close model plots

% Run ray_parameter
fprintf('  Running ray_parameter...\n');
run('ray_parameter.m');
% Extract data from workspace variables
params_ray.source_depth = source.depth;
params_ray.receiver_depth = receiver.depth;
params_ray.receiver_rng = receiver.rng;
params_ray.freq = freq;
data_rayparam = extract_eigenrays_rayparam(eigenrays, eigenray_times, ...
    eigenray_absorption, eigenray_reflection, eigenray_geom_spreading, ...
    eigenray_arrival_angle, eigenray_indices, source.launch_angles, ...
    eigenray_n_bottom, eigenray_n_surface, params_ray);
close all;

% Run Bellhop
fprintf('  Running Bellhop...\n');
% Bellhop must be run separately via shell
% For now, skip if output files don't exist
if exist('scenario.ray', 'file')
    data_bellhop = extract_eigenrays_bellhop('scenario.env', 'scenario');
else
    fprintf('  Bellhop output not found, skipping...\n');
    data_bellhop = []; % empty for now
end

fprintf('Step 1 complete.\n\n');

%% Step 2: Compute comparisons

fprintf('Step 2: Computing pairwise comparisons...\n');

% Clinear vs Ray Parameter
comp_clin_ray = compare_eigenrays(data_clinear, data_rayparam, ...
    'time_tol', 0.5, 'require_bounce_match', true);

% Clinear vs Bellhop (if available)
if ~isempty(data_bellhop)
    comp_clin_bell = compare_eigenrays(data_clinear, data_bellhop, ...
        'time_tol', 0.5, 'require_bounce_match', true);
    comp_ray_bell = compare_eigenrays(data_rayparam, data_bellhop, ...
        'time_tol', 0.5, 'require_bounce_match', true);
else
    comp_clin_bell = [];
    comp_ray_bell = [];
end

fprintf('Step 2 complete.\n\n');

%% Step 3: Generate visualizations

fprintf('Step 3: Generating comparison plots...\n');

% Ray fan comparison (skip if no Bellhop)
if ~isempty(data_bellhop)
    fig1 = plot_ray_fan_comparison(data_clinear, data_rayparam, data_bellhop);
    saveas(fig1, 'figures/ray_fan_comparison.png');
    fprintf('  Saved: figures/ray_fan_comparison.png\n');

    fig2 = plot_impulse_response_comparison(data_clinear, data_rayparam, data_bellhop);
    saveas(fig2, 'figures/impulse_response_comparison.png');
    fprintf('  Saved: figures/impulse_response_comparison.png\n');

    fig3 = plot_eigenray_table(comp_clin_ray, comp_clin_bell);
    saveas(fig3, 'figures/eigenray_comparison_table.png');
    fprintf('  Saved: figures/eigenray_comparison_table.png\n');
else
    % Just compare the two custom models
    fprintf('  Generating 2-model comparison plots...\n');
    % For now, skip visualization until Bellhop is available
end

fprintf('Step 3 complete.\n\n');

%% Step 4: Generate LaTeX table for paper

fprintf('Step 4: Generating LaTeX table...\n');

fid = fopen('figures/eigenray_table.tex', 'w');
fprintf(fid, '\\begin{table}[h]\n');
fprintf(fid, '\\centering\n');
fprintf(fid, '\\caption{Eigenray Detection and Comparison}\n');
fprintf(fid, '\\begin{tabular}{lccc}\n');
fprintf(fid, '\\hline\n');
fprintf(fid, 'Model & N Eigenrays & $\\Delta$Time vs C-Linear (s) & $\\Delta$Amplitude vs C-Linear (dB) \\\\\n');
fprintf(fid, '\\hline\n');
fprintf(fid, 'C-Linear Curvature & %d & --- & --- \\\\\n', data_clinear.n_eigenrays);

% Ray Parameter row
if isfield(comp_clin_ray, 'mean_dt') && comp_clin_ray.n_matched > 0
    fprintf(fid, 'Ray Parameter & %d & $%.3f \\pm %.3f$ & $%.2f \\pm %.2f$ \\\\\n', ...
        data_rayparam.n_eigenrays, comp_clin_ray.mean_dt, comp_clin_ray.std_dt, ...
        comp_clin_ray.mean_dA, comp_clin_ray.std_dA);
else
    fprintf(fid, 'Ray Parameter & %d & N/A (no matches) & N/A (no matches) \\\\\n', ...
        data_rayparam.n_eigenrays);
end

% Bellhop row (if available)
if ~isempty(data_bellhop) && isfield(comp_clin_bell, 'mean_dt') && comp_clin_bell.n_matched > 0
    fprintf(fid, 'Bellhop & %d & $%.3f \\pm %.3f$ & $%.2f \\pm %.2f$ \\\\\n', ...
        data_bellhop.n_eigenrays, comp_clin_bell.mean_dt, comp_clin_bell.std_dt, ...
        comp_clin_bell.mean_dA, comp_clin_bell.std_dA);
elseif ~isempty(data_bellhop)
    fprintf(fid, 'Bellhop & %d & N/A (no matches) & N/A (no matches) \\\\\n', ...
        data_bellhop.n_eigenrays);
end
fprintf(fid, '\\hline\n');
fprintf(fid, '\\end{tabular}\n');
fprintf(fid, '\\end{table}\n');
fclose(fid);

fprintf('  Saved: figures/eigenray_table.tex\n');
fprintf('Step 4 complete.\n\n');

fprintf('=== ALL COMPARISONS COMPLETE ===\n');
fprintf('Figures saved to figures/ directory\n');
fprintf('LaTeX table: figures/eigenray_table.tex\n');
