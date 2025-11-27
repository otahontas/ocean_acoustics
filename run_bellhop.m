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

% Keep scenario.ray in main directory
fprintf('\nBellhop ray tracing complete.\n');

%% ==================== RUN BELLHOP WITH ARRIVAL OUTPUT ====================
fprintf('\nRunning Bellhop arrival calculation...\n');

% Create arrival-specific env file
copyfile('scenario.env', 'scenario_arrivals.env');

% Modify the ACTION line from 'E' (eigenrays) to 'A' (arrivals)
env_content = fileread('scenario_arrivals.env');
env_content = strrep(env_content, sprintf('''E''\n'), sprintf('''A''\n'));
fid = fopen('scenario_arrivals.env', 'w');
fprintf(fid, '%s', env_content);
fclose(fid);

% Copy to at directory and run
copyfile('scenario_arrivals.env', 'at/scenario_arrivals.env');
cd('at');
bellhop('scenario_arrivals');
cd('..');

% Copy arrivals file back
copyfile('at/scenario_arrivals.arr', 'scenario_arrivals.arr');
fprintf('Generated: scenario_arrivals.arr\n');

%% ==================== ANALYZE ARRIVALS ====================
fprintf('\n=== BELLHOP EIGENRAY DIAGNOSTICS ===\n');

% Load shared parameters
shared_params;

% Read arrivals file
[Arr, Pos] = read_arrivals_asc('scenario_arrivals.arr');

% Find receiver indices matching our setup
irr = find(abs(Pos.r.r - receiver.range) < 1e-6, 1);
ird = find(abs(Pos.r.z - receiver.depth) < 1e-6, 1);
isd = 1; % Single source depth

if isempty(irr) || isempty(ird)
    error('Receiver position not found in arrivals file');
end

% Extract eigenray data
Narr = Arr(irr, ird, isd).Narr;
fprintf('Found %d eigenrays\n', Narr);

for k = 1:Narr
    launch_angle = Arr(irr, ird, isd).SrcDeclAngle(k);
    arrival_angle = Arr(irr, ird, isd).RcvrDeclAngle(k);
    n_bottom = Arr(irr, ird, isd).NumBotBnc(k);
    n_surface = Arr(irr, ird, isd).NumTopBnc(k);

    % Arrival time (real part of delay)
    arrival_time = real(Arr(irr, ird, isd).delay(k));

    % Amplitude in dB
    amplitude_linear = abs(Arr(irr, ird, isd).A(k));
    amplitude_dB = 20*log10(amplitude_linear);

    % Calculate path length from time and average sound speed
    c_avg = 1500; % approximate
    path_length = arrival_time * c_avg;

    fprintf('Eigenray %d: Launch angle = %.2f°, Arrival angle = %.2f°, Bounces: %dB/%dS, Path length = %.2f m, Time = %.3f s, Amp = %.2f dB\n', ...
        k, launch_angle, arrival_angle, n_bottom, n_surface, path_length, arrival_time, amplitude_dB);
end

fprintf('============================\n\n');
