function fig = plot_impulse_response_comparison(data_clinear, data_rayparam, data_bellhop)
    % Create overlaid impulse response comparison

    fig = figure('Position', [100 100 1000 600], 'Color', 'w');
    hold on; box on;

    models = {data_clinear, data_rayparam, data_bellhop};
    names = {'C-Linear', 'Ray Param', 'Bellhop'};
    colors = {[0 0.4470 0.7410], [0.8500 0.3250 0.0980], [0.4660 0.6740 0.1880]};
    markers = {'o', 's', '^'};

    % Find global amplitude range
    all_amps = [];
    for i = 1:3
        all_amps = [all_amps; models{i}.amplitudes_dB];
    end
    Amax = max(all_amps);
    Amin = Amax - 80; % 80 dB dynamic range

    % Plot each model
    for i = 1:3
        data = models{i};

        for j = 1:data.n_eigenrays
            t = data.arrival_times(j);
            A = data.amplitudes_dB(j);

            % Skip if below threshold
            if A < Amin
                continue;
            end

            % Stem
            plot([t t], [Amin A], 'Color', colors{i}, 'LineWidth', 1.5);

            % Marker
            plot(t, A, markers{i}, 'Color', colors{i}, ...
                'MarkerFaceColor', colors{i}, 'MarkerSize', 6);
        end
    end

    xlabel('Arrival Time (s)');
    ylabel('Amplitude (dB)');
    title('Impulse Response Comparison');
    legend(names, 'Location', 'best');
    ylim([Amin Amax+5]);
    grid on;
end
