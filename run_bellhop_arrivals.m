%% Bellhop arrivals calculation
% Runs Bellhop in arrivals mode to generate impulse response data

clear; close all; clc;

% Initialize Acoustics Toolbox paths
cd('at');
at_init_matlab;
cd('..');

% Read original scenario file
fid = fopen('scenario.env', 'r');
lines = {};
while ~feof(fid)
    lines{end+1} = fgetl(fid);
end
fclose(fid);

% Modify RunType from 'E' to 'A' for arrivals calculation
% Line 56 contains 'E' - change to 'A'
lines{56} = '''A''';

% Write modified env file
fid = fopen('at/scenario_arrivals.env', 'w');
for i = 1:length(lines)
    fprintf(fid, '%s\n', lines{i});
end
fclose(fid);

% Run Bellhop in arrivals mode
fprintf('Running Bellhop (arrivals mode)...\n');
cd('at');
bellhop('scenario_arrivals');
cd('..');

% Read arrivals data
fprintf('Reading arrivals data...\n');
cd('at');
[Arr, Pos] = read_arrivals_asc('scenario_arrivals.arr');
cd('..');

% Extract data for first receiver (irr=1, ird=1, isd=1)
Narr = Arr(1, 1, 1).Narr;
src_angles = Arr(1, 1, 1).SrcDeclAngle(1:Narr);
rcvr_angles = Arr(1, 1, 1).RcvrDeclAngle(1:Narr);
delays = real(Arr(1, 1, 1).delay(1:Narr));
amplitudes = abs(Arr(1, 1, 1).A(1:Narr));

fprintf('Found %d eigenray arrivals\n', Narr);

% Create figure with arrival angles labeled
fprintf('Plotting arrivals...\n');
figure('Position', [100, 100, 1000, 600]);
set(gcf, 'Color', 'white');

stem(delays, amplitudes, 'LineWidth', 1.5);
hold on;

% Add angle labels above each stem
for i = 1:Narr
    text(delays(i), amplitudes(i), sprintf('  %.1f°', rcvr_angles(i)), ...
         'VerticalAlignment', 'bottom', ...
         'HorizontalAlignment', 'center', ...
         'FontSize', 9, ...
         'Color', [0.2 0.2 0.2]);
end

xlabel('Travel Time (s)');
ylabel('Amplitude');
title('Impulse Response with Arrival Angles');
grid on;
set(gca, 'Color', 'white');
hold off;

saveas(gcf, 'bellhop_arrivals.png');
fprintf('Saved: bellhop_arrivals.png\n');

% Display arrivals info
fprintf('\nArrivals file generated: at/scenario_arrivals.arr\n');
fprintf('This file contains amplitude-delay pairs for the impulse response.\n');

% Clean up temporary files
delete('at/scenario_arrivals.env');
delete('at/scenario_arrivals.prt');
