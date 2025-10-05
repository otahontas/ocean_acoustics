%% Compare C-Linear vs Bellhop eigenrays
clear; close all; clc;

%% Run C-Linear model
fprintf('Running C-Linear model...\n');
run_clinear;
saveas(gcf, 'clinear_output.png');
fprintf('Saved: clinear_output.png\n\n');

%% Run Bellhop
fprintf('Running Bellhop...\n');
run_bellhop;
fprintf('Saved: bellhop_output.png\n');
