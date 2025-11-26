function eig_data = extract_eigenrays_clinear(eigenrays, params)
    % Extract eigenray data from clinear_curvature output
    %
    % Inputs:
    %   eigenrays: cell array from clinear_curvature
    %   params: struct with (z_s, r_s, z_rec, r_rec, f)
    %
    % Output:
    %   eig_data: EigenrayData object

    eig_data = EigenrayData('clinear_curvature');

    n = length(eigenrays);
    eig_data.n_eigenrays = n;

    % Preallocate arrays
    eig_data.launch_angles = zeros(n, 1);
    eig_data.arrival_times = zeros(n, 1);
    eig_data.arrival_angles = nan(n, 1); % not computed in clinear
    eig_data.amplitudes_dB = zeros(n, 1);
    eig_data.path_lengths = zeros(n, 1);
    eig_data.n_surface_bounces = zeros(n, 1);
    eig_data.n_bottom_bounces = zeros(n, 1);
    eig_data.ray_paths = cell(n, 1);

    % Extract data from each eigenray
    for i = 1:n
        er = eigenrays{i};
        eig_data.launch_angles(i) = rad2deg(er.theta0);
        eig_data.arrival_times(i) = er.t_at_r;
        eig_data.amplitudes_dB(i) = 20*log10(abs(er.A_at_r));
        eig_data.path_lengths(i) = er.path_len;
        eig_data.n_surface_bounces(i) = er.n_surface;
        eig_data.n_bottom_bounces(i) = er.n_bottom;

        % Extract ray path (remove NaNs)
        finite_idx = ~isnan(er.rpath);
        eig_data.ray_paths{i} = [er.rpath(finite_idx)', er.zpath(finite_idx)'];
    end

    % Metadata
    eig_data.source_depth = params.z_s;
    eig_data.source_range = params.r_s;
    eig_data.receiver_depth = params.z_rec;
    eig_data.receiver_range = params.r_rec;
    eig_data.frequency = params.f;
end
