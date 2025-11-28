%% Shared Parameters for Ocean Acoustics Ray Tracing Models
% This file defines common parameters used by both clinear_curvature.m and ray_parameter.m
% to ensure fair comparison between models.

%% Environment parameters
env.max_depth = 8000;       % maximum depth (m)
env.max_range = 100000;     % maximum range (m)
env.z_min = 0;              % surface depth (m)
env.z_max = 8000;           % bottom depth (m)

%% Source parameters
source.depth = 1000;        % source depth (m)
source.range = 0;           % source range (m)

%% Receiver parameters
receiver.depth = 1000;      % receiver depth (m)
receiver.range = 100000;    % receiver range (m)
receiver.tolerance = 5;     % eigenray hit tolerance (m)

%% Ray fan parameters
ray_fan.angle_min = -30;    % minimum launch angle (degrees)
ray_fan.angle_max = 30;     % maximum launch angle (degrees)
ray_fan.num_angles = 10001; % number of rays in fan

%% Acoustic parameters
acoustic.frequency = 100;   % source frequency (Hz)

%% Sound speed profile (Munk)
ssp.c0 = 1500;              % reference sound speed (m/s)
ssp.z0 = 1300;              % reference depth (m)
ssp.epsilon = 0.00737;      % Munk profile scale parameter

%% Seabed parameters (Jensen Table 1.3: Sandy seabed)
seabed.rho_water = 1000;    % water density (kg/m³)
seabed.rho_bottom = 1900;   % bottom density (kg/m³) - ρb/ρw = 1.9
seabed.c_bottom = 1650;     % bottom sound speed (m/s) - cp/cw = 1.1
