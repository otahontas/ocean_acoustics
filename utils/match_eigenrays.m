function [matches, unmatched_A, unmatched_B] = match_eigenrays(data_A, data_B, tol_time, tol_bounces)
    % Match eigenrays between two models based on arrival time and bounce pattern
    %
    % Inputs:
    %   data_A, data_B: EigenrayData objects
    %   tol_time: tolerance for arrival time matching (seconds)
    %   tol_bounces: boolean, require exact bounce match
    %
    % Outputs:
    %   matches: struct array with fields (idx_A, idx_B, dt, dA_dB, bounces_A, bounces_B)
    %   unmatched_A: indices in A without match
    %   unmatched_B: indices in B without match

    n_A = data_A.n_eigenrays;
    n_B = data_B.n_eigenrays;

    matched_A = false(n_A, 1);
    matched_B = false(n_B, 1);
    matches = struct('idx_A', {}, 'idx_B', {}, 'dt', {}, 'dA_dB', {}, ...
        'bounces_A', {}, 'bounces_B', {});

    for i = 1:n_A
        t_A = data_A.arrival_times(i);
        b_A = [data_A.n_bottom_bounces(i), data_A.n_surface_bounces(i)];

        % Find candidates in B within time tolerance
        dt = abs(data_B.arrival_times - t_A);
        candidates = find(dt <= tol_time & ~matched_B);

        if tol_bounces
            % Filter by bounce pattern
            for j = candidates'
                b_B = [data_B.n_bottom_bounces(j), data_B.n_surface_bounces(j)];
                if all(b_A == b_B)
                    % Found match
                    match.idx_A = i;
                    match.idx_B = j;
                    match.dt = data_B.arrival_times(j) - t_A;
                    match.dA_dB = data_B.amplitudes_dB(j) - data_A.amplitudes_dB(i);
                    match.bounces_A = sprintf('%dB/%dS', b_A(1), b_A(2));
                    match.bounces_B = sprintf('%dB/%dS', b_B(1), b_B(2));
                    matches(end+1) = match;
                    matched_A(i) = true;
                    matched_B(j) = true;
                    break;
                end
            end
        else
            % Take closest in time
            if ~isempty(candidates)
                [~, best_idx] = min(dt(candidates));
                j = candidates(best_idx);
                b_B = [data_B.n_bottom_bounces(j), data_B.n_surface_bounces(j)];

                match.idx_A = i;
                match.idx_B = j;
                match.dt = data_B.arrival_times(j) - t_A;
                match.dA_dB = data_B.amplitudes_dB(j) - data_A.amplitudes_dB(i);
                match.bounces_A = sprintf('%dB/%dS', b_A(1), b_A(2));
                match.bounces_B = sprintf('%dB/%dS', b_B(1), b_B(2));
                matches(end+1) = match;
                matched_A(i) = true;
                matched_B(j) = true;
            end
        end
    end

    unmatched_A = find(~matched_A);
    unmatched_B = find(~matched_B);
end
