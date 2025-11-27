function eig_data = extract_eigenrays_rayparam(eigenrays, eigenray_times, ...
    eigenray_absorption, eigenray_reflection, eigenray_geom_spreading, ...
    eigenray_arrival_angle, eigenray_indices, source_launch_angles, ...
    eigenray_n_bottom, eigenray_n_surface, params)
    % Extract eigenray data from ray_parameter output

    eig_data = EigenrayData('ray_parameter');

    n = length(eigenrays);
    eig_data.n_eigenrays = n;

    % Direct assignment (already in arrays)
    % Extract launch angles from indices
    eig_data.launch_angles = rad2deg(source_launch_angles(eigenray_indices));
    eig_data.arrival_times = eigenray_times';
    eig_data.arrival_angles = eigenray_arrival_angle';

    % Compute total amplitude in dB
    A_total = eigenray_geom_spreading .* eigenray_absorption .* eigenray_reflection;
    eig_data.amplitudes_dB = 20*log10(abs(A_total))';

    % Path lengths (need to compute from eigenrays)
    eig_data.path_lengths = zeros(n, 1);
    eig_data.ray_paths = cell(n, 1);
    for i = 1:n
        ray = eigenrays{i};
        eig_data.ray_paths{i} = ray; % already [N x 2]
        % Compute path length
        dr = diff(ray(:,1));
        dz = diff(ray(:,2));
        eig_data.path_lengths(i) = sum(sqrt(dr.^2 + dz.^2));
    end

    % Bounce counts (now available from ray_parameter.m)
    eig_data.n_surface_bounces = eigenray_n_surface';
    eig_data.n_bottom_bounces = eigenray_n_bottom';

    % Metadata
    eig_data.source_depth = params.source_depth;
    eig_data.source_range = 0;
    eig_data.receiver_depth = params.receiver_depth;
    eig_data.receiver_range = params.receiver_rng;
    eig_data.frequency = params.freq;
end
