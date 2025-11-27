function eig_data = extract_eigenrays_bellhop(scenario_file, output_prefix)
    % Extract eigenray data from Bellhop output files
    %
    % Inputs:
    %   scenario_file: path to .env file
    %   output_prefix: e.g., 'scenario' (reads scenario.ray, scenario.arr)
    %
    % Output:
    %   eig_data: EigenrayData object

    eig_data = EigenrayData('bellhop');

    % Read Bellhop output using AT functions
    % Note: Bellhop eigenray output is in .ray file
    ray_file = [output_prefix '.ray'];

    if ~exist(ray_file, 'file')
        error('Bellhop output file not found: %s', ray_file);
    end

    % Use AT toolbox function to read rays
    % plotray expects global variables set by bellhop
    % We need to manually parse the .ray file

    % Read .ray file (Bellhop format - matching plotray.m)
    fid = fopen(ray_file, 'r');

    % Header (following plotray.m format)
    Title = fgetl(fid);
    freq = fscanf(fid, '%f', 1);
    Nsxyz = fscanf(fid, '%f', 3); % [Nsx Nsy Nsz]
    NBeamAngles = fscanf(fid, '%i', 2); % [Nalpha Nbeta]

    DepthT = fscanf(fid, '%f', 1);
    DepthB = fscanf(fid, '%f', 1);

    Type = fgetl(fid); % consume newline
    Type = fgetl(fid); % read type line (e.g., 'rz')

    Nsz = Nsxyz(3);
    Nalpha = NBeamAngles(1);

    % Preallocate
    eig_data.launch_angles = [];
    eig_data.arrival_times = [];
    eig_data.arrival_angles = [];
    eig_data.amplitudes_dB = [];
    eig_data.path_lengths = [];
    eig_data.ray_paths = {};
    eig_data.n_surface_bounces = [];
    eig_data.n_bottom_bounces = [];

    eigenray_count = 0;

    % Read rays (following plotray.m structure)
    for isz = 1:Nsz
        for ibeam = 1:Nalpha
            alpha0 = fscanf(fid, '%f', 1); % launch angle
            nsteps = fscanf(fid, '%i', 1);

            NumTopBnc = fscanf(fid, '%i', 1);
            NumBotBnc = fscanf(fid, '%i', 1);

            if isempty(nsteps); break; end

            % Read ray points [r; z]
            ray_data = fscanf(fid, '%f', [2, nsteps]);
            ray_path = ray_data'; % transpose to [nsteps x 2]

            % In eigenray mode, all rays should be eigenrays
            eigenray_count = eigenray_count + 1;
            eig_data.launch_angles(eigenray_count) = alpha0;
            eig_data.n_surface_bounces(eigenray_count) = NumTopBnc;
            eig_data.n_bottom_bounces(eigenray_count) = NumBotBnc;
            eig_data.ray_paths{eigenray_count} = ray_path;

            % Compute path length
            dr = diff(ray_path(:,1));
            dz = diff(ray_path(:,2));
            eig_data.path_lengths(eigenray_count) = sum(sqrt(dr.^2 + dz.^2));

            % Compute arrival time (approx with average c)
            c_avg = 1500; % m/s
            eig_data.arrival_times(eigenray_count) = eig_data.path_lengths(eigenray_count) / c_avg;

            % Arrival angle (last segment)
            dx = ray_path(end,1) - ray_path(end-1,1);
            dz = ray_path(end,2) - ray_path(end-1,2);
            eig_data.arrival_angles(eigenray_count) = rad2deg(atan2(dz, dx));
        end
    end

    fclose(fid);

    eig_data.n_eigenrays = eigenray_count;

    % Trim arrays
    eig_data.launch_angles = eig_data.launch_angles(1:eigenray_count);
    eig_data.arrival_times = eig_data.arrival_times';
    eig_data.arrival_angles = eig_data.arrival_angles';
    eig_data.path_lengths = eig_data.path_lengths';
    eig_data.n_surface_bounces = eig_data.n_surface_bounces';
    eig_data.n_bottom_bounces = eig_data.n_bottom_bounces';

    % Amplitude: Bellhop doesn't directly give amplitude per eigenray in .ray file
    % Need to read .arr file or use approximate TL
    eig_data.amplitudes_dB = nan(eigenray_count, 1);

    % Metadata from scenario file
    [params] = read_scenario_params(scenario_file);
    eig_data.source_depth = params.z_s;
    eig_data.source_range = params.r_s;
    eig_data.receiver_depth = params.z_rec;
    eig_data.receiver_range = params.r_rec;
    eig_data.frequency = params.freq;
end

function params = read_scenario_params(env_file)
    % Parse key parameters from .env file
    fid = fopen(env_file, 'r');
    fgetl(fid); % title
    params.freq = fscanf(fid, '%f', 1);
    fgetl(fid); fgetl(fid); fgetl(fid);

    % Skip SSP (read until 'A')
    while true
        line = fgetl(fid);
        if contains(line, '''A''')
            break;
        end
    end

    % Source depth
    params.z_s = fscanf(fid, '%f', 1);
    fgetl(fid);

    % Receiver depth
    params.z_rec = fscanf(fid, '%f', 1);
    fgetl(fid);

    % Receiver range
    params.r_rec = fscanf(fid, '%f', 1);
    fgetl(fid);

    params.r_s = 0;
    fclose(fid);
end
