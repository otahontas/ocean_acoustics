function comparison = compare_eigenrays(data_A, data_B, options)
    % Compute comparison metrics between two eigenray datasets
    %
    % Inputs:
    %   data_A, data_B: EigenrayData objects
    %   options: struct with (time_tol, require_bounce_match)
    %
    % Output:
    %   comparison: struct with metrics and matched eigenrays

    arguments
        data_A EigenrayData
        data_B EigenrayData
        options.time_tol = 0.5; % seconds
        options.require_bounce_match = true;
    end

    fprintf('\n=== COMPARING %s vs %s ===\n', ...
        upper(data_A.model_name), upper(data_B.model_name));

    % Match eigenrays
    [matches, unmatched_A, unmatched_B] = match_eigenrays(...
        data_A, data_B, options.time_tol, options.require_bounce_match);

    comparison.data_A = data_A;
    comparison.data_B = data_B;
    comparison.matches = matches;
    comparison.unmatched_A = unmatched_A;
    comparison.unmatched_B = unmatched_B;

    % Summary statistics
    comparison.n_matched = length(matches);
    comparison.n_A_only = length(unmatched_A);
    comparison.n_B_only = length(unmatched_B);

    fprintf('Eigenrays in %s: %d\n', data_A.model_name, data_A.n_eigenrays);
    fprintf('Eigenrays in %s: %d\n', data_B.model_name, data_B.n_eigenrays);
    fprintf('Matched eigenrays: %d\n', comparison.n_matched);
    fprintf('%s only: %d\n', data_A.model_name, comparison.n_A_only);
    fprintf('%s only: %d\n', data_B.model_name, comparison.n_B_only);

    if comparison.n_matched > 0
        % Compute differences for matched eigenrays
        dt = [matches.dt];
        dA = [matches.dA_dB];

        comparison.mean_dt = mean(dt);
        comparison.std_dt = std(dt);
        comparison.max_dt = max(abs(dt));

        comparison.mean_dA = mean(dA);
        comparison.std_dA = std(dA);
        comparison.max_dA = max(abs(dA));

        fprintf('\nTiming differences:\n');
        fprintf('  Mean: %.3f s, Std: %.3f s, Max: %.3f s\n', ...
            comparison.mean_dt, comparison.std_dt, comparison.max_dt);

        fprintf('\nAmplitude differences:\n');
        fprintf('  Mean: %.2f dB, Std: %.2f dB, Max: %.2f dB\n', ...
            comparison.mean_dA, comparison.std_dA, comparison.max_dA);
    end

    fprintf('==============================\n\n');
end
