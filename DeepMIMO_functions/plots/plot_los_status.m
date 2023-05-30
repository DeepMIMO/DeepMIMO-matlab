function [] = plot_los_status(dataset, bs)
    if bs>length(dataset) || bs<1
        warning('BS to be plotted should selected in [1, %i]', length(dataset));
        warning('Plotting the first basestation.');
        bs = 1;
    end
    figure;
    hold on;
    i = bs;
    bs_loc = dataset{i}.loc;
    user_locs = zeros(length(dataset{i}.user), 2);
    user_los = zeros(length(dataset{i}.user), 1);
    for j = 1:length(dataset{i}.user)
        user_locs(j, :) = dataset{i}.user{j}.loc(1:2);
        user_los(j) = dataset{i}.user{j}.LoS_status;
    end

    colors = ["rx", "bx", "gx"];
    legends = ["UE (No Path)", "UE (NLoS)", "UE (LoS)"];
    for los_status = [-1, 0, 1]
        select_users = user_los == los_status;
        plot(user_locs(select_users, 1), user_locs(select_users, 2), colors(los_status+2), 'DisplayName', legends(los_status+2), 'MarkerSize', 1.5);
    end

    plot(bs_loc(1), bs_loc(2), 'ko', 'DisplayName', 'BS', 'MarkerSize', 4);
    legend;
    grid on;
end
            