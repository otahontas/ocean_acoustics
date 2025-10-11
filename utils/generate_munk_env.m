function generate_munk_env(output_filename, num_points)
% GENERATE_MUNK_ENV Creates a Bellhop .env file for the Munk profile.
%   GENERATE_MUNK_ENV(output_filename, num_points) generates a scenario file
%   with the specified number of SSP points.

if nargin < 2
    num_points = 42;
end
if nargin < 1
    output_filename = 'scenario_munk.env';
end

%% Parameters from discretizedClinearWITHREFLECTIONS.m

% Munk SSP
c0 = 1450;           % reference speed (m/s)
z0_munk = 1300;      % reference depth (m)
eps_munk = 0.01;     % scale epsilon
B = 800;             % scale depth (m)
c_of_z = @(z) c0 .* ( 1 + eps_munk .* ( ((z - z0_munk)./B) - 1 + exp(-(z - z0_munk)./B) ) );

% Boundaries
z_min = 0; % surface (m)
z_max = 8000; % bottom (m)

% Source/receiver
z_s = 1000;    % source depth (m)
r_rec_km = 100; % receiver range (km)
z_rec = 1000;  % receiver depth (m)

% Beam parameters
angle_min = -60.0;
angle_max = 60.0;
ds = 30.0;

%% Generate the file content

fid = fopen(output_filename, 'w');

% File Header
fprintf(fid, '
'); % Changed from ''Munk Profile (Generated)'' to '' to fix escaping
fprintf(fid, '50.0
'); % Frequency
fprintf(fid, '1
'); % Nmedia
fprintf(fid, '
'); % Changed from ''CVW'' to '' to fix escaping % SSP Options

% Sound Speed Profile
depth_points = linspace(z_min, z_max, num_points);
ssp_points = c_of_z(depth_points);

fprintf(fid, '%d %.1f %.1f\n', num_points, z_min, z_max);
for i = 1:num_points
    fprintf(fid, '   %.2f  %.2f  /\n', depth_points(i), ssp_points(i));
end

% Boundaries and Geometry
fprintf(fid, '
'); % Changed from ''A*'' to '' to fix escaping 0.0
fprintf(fid, '%.1f 1600.0 0.0 1.5 0.0 0.0 /\n', z_max);

fprintf(fid, '1\n'); % Ns
fprintf(fid, '%.1f /\n', z_s);

fprintf(fid, '1\n'); % Nr
fprintf(fid, '%.1f /\n', z_rec);

fprintf(fid, '1\n'); % Nrr
fprintf(fid, '%.1f /\n', r_rec_km);

% Beams
fprintf(fid, '
'); % Changed from ''E'' to '' to fix escaping % Eigenray beams
fprintf(fid, '%d\n', 501); % Nbeams (default)
fprintf(fid, '%.1f %.1f /\n', angle_min, angle_max);

% Step size and other params
fprintf(fid, '%.1f %.1f %.1f\n', ds, 9000.0, 120.0); % ds, z_max_plot, r_max_plot

fclose(fid);

fprintf('Successfully generated environment file: %s\n', output_filename);

end
