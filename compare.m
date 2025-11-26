%% Compare ray tracing models vs Bellhop
clear; close all; clc;

%% Run C-Linear Curvature model
fprintf('Running C-Linear Curvature model...\n');
clinear_curvature;

%% Run Ray Parameter model
fprintf('Running Ray Parameter model...\n');
ray_parameter;

%% Run Bellhop
fprintf('Running Bellhop...\n');
run_bellhop;
