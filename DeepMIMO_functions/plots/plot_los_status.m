function [] = plot_los_status(bs_dataset)

    figure;
    hold on;
    bs_loc = bs_dataset.loc;
    user_locs = zeros(length(bs_dataset.user), 2);
    user_los = zeros(length(bs_dataset.user), 1);
    for j = 1:length(bs_dataset.user)
        user_locs(j, :) = bs_dataset.user{j}.loc(1:2);
        user_los(j) = bs_dataset.user{j}.LoS_status;
    end

    colors = ["rx", "bx", "gx"];
    legends = ["UE (No Path)", "UE (NLoS)", "UE (LoS)"];
    for los_status = [-1, 0, 1]
        select_users = user_los == los_status;
        plot(user_locs(select_users, 1), user_locs(select_users, 2), colors(los_status+2), 'DisplayName', legends(los_status+2), 'MarkerSize', 3);
    end

    plot(bs_loc(1), bs_loc(2), 'ko', 'DisplayName', 'BS', 'MarkerSize', 4);
    legend;
    grid on;
end
            