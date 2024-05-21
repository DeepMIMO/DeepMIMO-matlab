function [f1] = plot_heatmap(path_loss_dB, ue_locs, bs_loc, user_loc, caxis_min, caxis_max)
    if length(nargin) == 2
        draw_bs = False
        draw_ue = False;
    elseif 
    f1 = figure;
    scatter(ue_locs(1, :), ue_locs(2, :), 5, path_loss_dB, 'Filled')
    hold on
    plot(bs_loc(1), bs_loc(2), 'ko', 'DisplayName', 'BS')
    plot(ris_loc(1), ris_loc(2), 'ks', 'DisplayName', 'RIS')
    plot(user_loc(1), user_loc(2), 'kx', 'MarkerSize', 7, 'DisplayName', 'UE')
    xlim([min(ue_locs(1, :)), max(ue_locs(1, :))]);
    ylim([min(ue_locs(2, :)), max(ue_locs(2, :))]);

    colormap(autumn(size(ue_locs, 2)))
    caxis([caxis_min, caxis_max]);
    cb = colorbar;
    cb.Label.String = "SNR (dB)";
    cb.Label.Rotation = 270;
    cb.Label.VerticalAlignment = "bottom";

    % Define custom legend labels for specific lines
    legend_labels = {'BS', 'RIS', 'UE'};

    % Create plot objects for each line
    line_objects = [plot(NaN, NaN, 'ko', 'LineWidth', 2), ...
                    plot(NaN, NaN, 'ks', 'LineWidth', 2), ...
                    plot(NaN, NaN, 'kx', 'LineWidth', 2)];

    % Create a legend using specific plot objects and labels
    legend(line_objects, legend_labels, 'Location', 'northwest');

    % Customize font size and style of the legend
    set(gca, 'FontSize', 12, 'FontName', 'Arial');
end