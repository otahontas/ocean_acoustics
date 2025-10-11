function scenario = read_scenario(filename)
% READ_SCENARIO Parses a Bellhop-style environment file.
%   scenario = READ_SCENARIO(filename) reads the specified file and
%   returns a struct containing the scenario parameters.

fid = fopen(filename, 'r');

% Skip file header
fgetl(fid); fgetl(fid); fgetl(fid); fgetl(fid);

% Read Sound Speed Profile (SSP)
line = strsplit(strtrim(fgetl(fid)));
scenario.n_ssp = str2double(line{1});
scenario.z_min = str2double(line{2}); % Top boundary
scenario.z_max = str2double(line{3}); % Bottom boundary

scenario.ssp_z = zeros(scenario.n_ssp, 1);
scenario.ssp_c = zeros(scenario.n_ssp, 1);
for i = 1:scenario.n_ssp
    line = strsplit(strtrim(fgetl(fid)));
    scenario.ssp_z(i) = str2double(line{1});
    scenario.ssp_c(i) = str2double(line{2});
end

% Skip boundary condition lines
fgetl(fid); fgetl(fid);

% Read source and receiver geometry
fgetl(fid); % skip source count
line = strsplit(strtrim(fgetl(fid)));
scenario.z_s = str2double(line{1}); % Source depth

fgetl(fid); % skip receiver depth count
line = strsplit(strtrim(fgetl(fid)));
scenario.z_rec = str2double(line{1}); % Receiver depth

fgetl(fid); % skip receiver range count
line = strsplit(strtrim(fgetl(fid)));
scenario.r_rec = str2double(line{1}) * 1000; % Receiver range (km to m)

% Read beam parameters
fgetl(fid); fgetl(fid); % skip beam type and count
line = strsplit(strtrim(fgetl(fid)));
scenario.angle_min = str2double(line{1}); % Minimum launch angle
scenario.angle_max = str2double(line{2}); % Maximum launch angle

line = strsplit(strtrim(fgetl(fid)));
scenario.ds = str2double(line{1}); % Step size (m)

fclose(fid);

end
