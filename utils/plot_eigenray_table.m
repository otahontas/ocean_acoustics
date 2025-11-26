function fig = plot_eigenray_table(comparison_AB, comparison_AC)
    % Create visual table comparing eigenray matches
    %
    % Inputs: comparison structs from compare_eigenrays

    fig = figure('Position', [100 100 1200 800], 'Color', 'w');

    % Create table data
    model_A = comparison_AB.data_A.model_name;
    model_B = comparison_AB.data_B.model_name;
    model_C = comparison_AC.data_B.model_name;

    % Summary table
    data = {
        model_A, comparison_AB.data_A.n_eigenrays, '-', '-';
        model_B, comparison_AB.data_B.n_eigenrays, ...
            sprintf('%.3f ± %.3f s', comparison_AB.mean_dt, comparison_AB.std_dt), ...
            sprintf('%.2f ± %.2f dB', comparison_AB.mean_dA, comparison_AB.std_dA);
        model_C, comparison_AC.data_B.n_eigenrays, ...
            sprintf('%.3f ± %.3f s', comparison_AC.mean_dt, comparison_AC.std_dt), ...
            sprintf('%.2f ± %.2f dB', comparison_AC.mean_dA, comparison_AC.std_dA);
    };

    colNames = {'Model', 'N Eigenrays', sprintf('ΔTime vs %s', model_A), sprintf('ΔAmplitude vs %s', model_A)};

    uitable(fig, 'Data', data, 'ColumnName', colNames, ...
        'Units', 'normalized', 'Position', [0.1 0.5 0.8 0.4], ...
        'FontSize', 12);

    % Add text annotations
    annotation(fig, 'textbox', [0.1 0.85 0.8 0.1], ...
        'String', 'Eigenray Comparison Summary', ...
        'FontSize', 14, 'FontWeight', 'bold', ...
        'HorizontalAlignment', 'center', 'LineStyle', 'none');
end
