classdef EigenrayData
    % Common eigenray data format for all models
    properties
        model_name          % string: 'clinear', 'rayparam', 'bellhop'
        n_eigenrays         % int: number of eigenrays
        launch_angles       % array [n_eigenrays x 1]: degrees
        arrival_times       % array [n_eigenrays x 1]: seconds
        arrival_angles      % array [n_eigenrays x 1]: degrees (NaN if not available)
        amplitudes_dB       % array [n_eigenrays x 1]: dB
        path_lengths        % array [n_eigenrays x 1]: meters
        n_surface_bounces   % array [n_eigenrays x 1]: int
        n_bottom_bounces    % array [n_eigenrays x 1]: int
        ray_paths           % cell array [n_eigenrays x 1]: {[N x 2] matrices of (r,z)}

        % Metadata
        source_depth        % meters
        source_range        % meters
        receiver_depth      % meters
        receiver_range      % meters
        frequency           % Hz
    end

    methods
        function obj = EigenrayData(model_name)
            obj.model_name = model_name;
        end

        function summary(obj)
            fprintf('=== %s MODEL ===\n', upper(obj.model_name));
            fprintf('Eigenrays found: %d\n', obj.n_eigenrays);
            fprintf('Launch angles: %.2f° to %.2f°\n', min(obj.launch_angles), max(obj.launch_angles));
            fprintf('Arrival times: %.2f s to %.2f s\n', min(obj.arrival_times), max(obj.arrival_times));
            fprintf('Amplitudes: %.2f dB to %.2f dB\n', min(obj.amplitudes_dB), max(obj.amplitudes_dB));
            fprintf('Bounce patterns: %dB/%dS to %dB/%dS\n', ...
                min(obj.n_bottom_bounces), min(obj.n_surface_bounces), ...
                max(obj.n_bottom_bounces), max(obj.n_surface_bounces));
        end
    end
end
