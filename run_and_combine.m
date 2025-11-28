%% Run comparison and combine all figures into one
% This wrapper script runs compare.m and then combines all generated
% figures into a single comparison figure without modifying the original files

clear; close all; clc;

fprintf('Running model comparison...\n');
compare;

fprintf('\nCombining figures...\n');

% Get all figure handles (they're created in the order the scripts run)
figs = findall(0, 'Type', 'figure');
num_figs = length(figs);

fprintf('Found %d figures to combine\n', num_figs);

% Reverse order since findall returns newest first
figs = figs(end:-1:1);

% Create combined figure with 2 rows x 3 columns layout
fig_combined = figure('Position', [50 50 1800 1200], 'Color', 'w');

% Determine grid size based on number of figures
if num_figs <= 3
    nrows = 1;
    ncols = num_figs;
elseif num_figs <= 6
    nrows = 2;
    ncols = 3;
else
    nrows = ceil(num_figs / 3);
    ncols = 3;
end

% Copy each figure's content to subplot
for i = 1:num_figs
    % Create subplot
    subplot(nrows, ncols, i);

    % Get the axes from the original figure
    orig_axes = findall(figs(i), 'Type', 'axes');

    if ~isempty(orig_axes)
        % Use the first (or only) axes if multiple exist
        orig_ax = orig_axes(1);

        % Copy all children (plots, lines, patches, etc.) to current subplot
        copyobj(allchild(orig_ax), gca);

        % Copy axes properties
        title(get(get(orig_ax, 'Title'), 'String'));
        xlabel(get(get(orig_ax, 'XLabel'), 'String'));
        ylabel(get(get(orig_ax, 'YLabel'), 'String'));

        % Copy axis direction and limits
        set(gca, 'YDir', get(orig_ax, 'YDir'));
        set(gca, 'XLim', get(orig_ax, 'XLim'));
        set(gca, 'YLim', get(orig_ax, 'YLim'));

        % Copy grid
        if strcmp(get(orig_ax, 'XGrid'), 'on')
            grid on;
        end

        % Make box
        box on;
    end
end

% Add overall title
sgtitle('Ray Tracing Model Comparison: C-Linear Curvature vs Ray Parameter vs Bellhop', ...
    'FontSize', 14, 'FontWeight', 'bold');

% Save combined figure
saveas(fig_combined, 'figures/combined_comparison.png');
fprintf('Saved combined figure: figures/combined_comparison.png\n');

% Also save as high-resolution PDF for paper
exportgraphics(fig_combined, 'figures/combined_comparison.pdf', 'Resolution', 300);
fprintf('Saved high-res PDF: figures/combined_comparison.pdf\n');

fprintf('\nCombination complete!\n');
