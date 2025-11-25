%% Simple Bellhop runner
% Reads scenario.env, runs Bellhop, and plots rays

clear; close all; clc;

% Initialize Acoustics Toolbox paths
cd('at');
at_init_matlab;
cd('..');

% Copy env file to at directory
copyfile('scenario.env', 'at/scenario.env');

% Run Bellhop
fprintf('Running Bellhop...\n');
cd('at');
bellhop('scenario');
cd('..');

% Plot rays
fprintf('Plotting rays...\n');
figure;
set(gcf, 'Color', 'white');
set(gca, 'Color', 'white');
plotray('at/scenario.ray');
saveas(gcf, 'bellhop_output.png');
fprintf('Saved: bellhop_output.png\n');

% Clean up temporary files
delete('at/scenario.env');
delete('at/scenario.prt');
delete('at/scenario.ray');
