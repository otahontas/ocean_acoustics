%% Simple Bellhop runner
% Reads scenario.env, runs Bellhop, and plots rays

clear; close all; clc;

addpath('at/Matlab/');
addpath('at/Matlab/Plot/');

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
plotray('at/scenario.ray');
saveas(gcf, 'bellhop_output.png');
fprintf('Saved: bellhop_output.png\n');
