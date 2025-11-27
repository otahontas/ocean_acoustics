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

%% Parameters matching clinear_curvature.m and ray_parameter.m

% Munk SSP (Jensen standard form)
c0 = 1500;           % reference speed (m/s)
z0_munk = 1300;      % reference depth (m)
eps_munk = 0.00737;  % scale epsilon
c_of_z = @(z) c0 .* ( 1 + eps_munk .* ((2*(z - z0_munk)./z0_munk) - 1 + exp(-2*(z - z0_munk)./z0_munk)));

% Boundaries
z_min = 0; % surface (m)
z_max = 8000; % bottom (m)

% Source/receiver
z_s = 1000;    % source depth (m)
r_rec_km = 100; % receiver range (km)
z_rec = 1000;  % receiver depth (m)

% Beam parameters (matching clinear/ray_parameter)
angle_min = -30.0;
angle_max = 30.0;
num_beams = 10001;
ds = 30.0;

%% Generate the file content

fid = fopen(output_filename, 'w');

% File Header
fprintf(fid, '''Munk eigenrays''\n');
fprintf(fid, '50.0\n');
fprintf(fid, '1\n');
fprintf(fid, '''CVW''\n');

% Sound Speed Profile
depth_points = linspace(z_min, z_max, num_points);
ssp_points = c_of_z(depth_points);

fprintf(fid, '%d %.1f %.1f\n', num_points, z_min, z_max);
for i = 1:num_points
    fprintf(fid, '   %.2f  %.2f  /\n', depth_points(i), ssp_points(i));
end

% Boundaries and Geometry
fprintf(fid, '''A'' 0.0\n');
fprintf(fid, '%.1f 1650.0 0.0 1.9 0.0 0.0 /\n', z_max);

fprintf(fid, '1\n'); % Ns
fprintf(fid, '%.1f /\n', z_s);

fprintf(fid, '1\n'); % Nr
fprintf(fid, '%.1f /\n', z_rec);

fprintf(fid, '1\n'); % Nrr
fprintf(fid, '%.1f /\n', r_rec_km);

% Beams
fprintf(fid, '''E''\n');
fprintf(fid, '%d\n', num_beams);
fprintf(fid, '%.1f %.1f /\n', angle_min, angle_max);

% Step size and other params
fprintf(fid, '%.1f %.1f %.1f\n', ds, 9000.0, 120.0); % ds, z_max_plot, r_max_plot

fclose(fid);

fprintf('Successfully generated environment file: %s\n', output_filename);

end
