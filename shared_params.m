%% Shared Parameters for Ocean Acoustics Ray Tracing Models
% This file defines common parameters used by both clinear_curvature.m and ray_parameter.m
% to ensure fair comparison between models.

%% Environment parameters
env.max_depth = 8000;       % maximum depth (m)
env.max_range = 18000;      % maximum range (m) - 15km + 20% buffer
env.z_min = 0;              % surface depth (m)
env.z_max = 8000;           % bottom depth (m)

%% Source parameters
source.depth = 100;         % source depth (m) - shallow source
source.range = 0;           % source range (m)

%% Receiver parameters
receiver.depth = 2000;      % receiver depth (m) - deep receiver below sound channel
receiver.range = 15000;     % receiver range (m) - 15km medium range
receiver.tolerance = 10;    % eigenray hit tolerance (m)

%% Ray fan parameters
ray_fan.angle_min = -20;    % minimum launch angle (degrees) - narrower for speed
ray_fan.angle_max = 20;     % maximum launch angle (degrees) - narrower for speed
ray_fan.num_angles = 501;   % number of rays in fan (reduced for faster computation)

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
