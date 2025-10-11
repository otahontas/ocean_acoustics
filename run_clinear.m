%% Simple C-Linear runner

clear; close all; clc;

% Add paths to model and utils
addpath('clinear');
addpath('utils');

% Run C-Linear model
fprintf('Running C-Linear model...\n');
clinear('scenario.env');

% Save output
saveas(gcf, 'clinear_output.png');
fprintf('Saved: clinear_output.png\n');