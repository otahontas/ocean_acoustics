function fig = plot_ray_fan_comparison(data_clinear, data_rayparam, data_bellhop)
    % Create 3-panel side-by-side ray fan comparison
    %
    % Inputs: EigenrayData objects for each model
    % Output: figure handle

    fig = figure('Position', [100 100 1800 600], 'Color', 'w');

    models = {data_clinear, data_rayparam, data_bellhop};
    titles = {'C-Linear Curvature', 'Ray Parameter (Jacobian)', 'Bellhop'};

    z_max = 8000;
    r_max = 100000;

    for i = 1:3
        subplot(1, 3, i);
        hold on; box on;

        data = models{i};

        % Plot eigenrays
        for j = 1:data.n_eigenrays
            ray = data.ray_paths{j};

            % Color by bounce pattern
            nb = data.n_bottom_bounces(j);
            ns = data.n_surface_bounces(j);
            total_bounces = nb + ns;

            if total_bounces == 0
                color = [0 0.4470 0.7410]; % blue (direct)
            elseif total_bounces == 1
                color = [0.8500 0.3250 0.0980]; % orange (1 bounce)
            elseif total_bounces == 2
                color = [0.9290 0.6940 0.1250]; % yellow (2 bounces)
            else
                color = [0.4940 0.1840 0.5560]; % purple (3+ bounces)
            end

            plot(ray(:,1)/1000, ray(:,2), 'Color', color, 'LineWidth', 1.2);
        end

        % Mark source and receiver
        plot(data.source_range/1000, data.source_depth, 'kp', ...
            'MarkerFaceColor', 'k', 'MarkerSize', 12, 'DisplayName', 'Source');
        plot(data.receiver_range/1000, data.receiver_depth, 'ro', ...
            'MarkerFaceColor', 'r', 'MarkerSize', 10, 'DisplayName', 'Receiver');

        % Boundaries
        plot([0 r_max/1000], [0 0], 'b-', 'LineWidth', 2); % surface
        plot([0 r_max/1000], [z_max z_max], 'Color', [0.6 0.3 0], 'LineWidth', 2); % bottom

        set(gca, 'YDir', 'reverse');
        xlabel('Range (km)');
        ylabel('Depth (m)');
        title(sprintf('%s\n%d eigenrays', titles{i}, data.n_eigenrays));
        xlim([0 r_max/1000]);
        ylim([0 z_max+500]);
        grid on;
    end

    sgtitle('Ray Fan Comparison: Three Models', 'FontSize', 14, 'FontWeight', 'bold');
end
