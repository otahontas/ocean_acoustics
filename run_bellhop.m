%% Simple Bellhop runner
% Reads scenario.env, runs Bellhop, and generates scenario.ray for comparison

clear; close all; clc;

% Initialize Acoustics Toolbox paths
fprintf('Initializing Acoustics Toolbox...\n');
cd('at');
at_init_matlab;
cd('..');

% Copy env file to at directory
copyfile('scenario.env', 'at/scenario.env');

% Run Bellhop
fprintf('Running Bellhop eigenray tracing...\n');
cd('at');
bellhop('scenario');
cd('..');

% Copy ray file back to main directory for comparison
copyfile('at/scenario.ray', 'scenario.ray');
fprintf('Generated: scenario.ray\n');

% Plot rays (optional)
fprintf('Plotting rays...\n');
figure;
plotray('at/scenario.ray');
title('Bellhop Ray Paths');
xlabel('Range (km)');
ylabel('Depth (m)');
saveas(gcf, 'figures/bellhop_rays.png');
fprintf('Saved: figures/bellhop_rays.png\n');

% Keep scenario.ray in main directory, clean up at/ directory copies
fprintf('\nBellhop complete. Ready for 3-model comparison.\n');
fprintf('Run: generate_comparisons.m\n');
