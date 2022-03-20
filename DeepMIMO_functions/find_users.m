function [users_ids, num_user] = find_users(params)

    rng(5); % For reproducibility with the same parameters

    user_grids = params.user_grids;
    start_of_grids = user_grids(:, 1);
    end_of_grids = user_grids(:, 2);
    users_per_row = user_grids(:, 3);

    users_per_grid = ((end_of_grids-start_of_grids)+1).*users_per_row;
    rows =  [params.active_user_first:params.active_user_last];
    num_of_subsampled_rows = round(length(rows)*params.row_subsampling);
    assert(num_of_subsampled_rows>=1, 'At least 1 row of users should be sampled! Please increase row subsampling rate.');
    rows = rows(randperm(length(rows),num_of_subsampled_rows));

    prev_grids = rows > end_of_grids;
    id_from_prev_grids = sum(prev_grids .* users_per_grid, 1);
    curr_grids = rows >= start_of_grids & rows <= end_of_grids;
    id_from_curr_grids = sum((rows - start_of_grids).*curr_grids.*users_per_row, 1);
    users = sum(id_from_prev_grids + id_from_curr_grids, 1);
    row_select = nonzeros(curr_grids.*users_per_row);
    users_ids = [];
    for i=1:length(row_select)
        users_in_row = [1:row_select(i)];
        num_of_subsampled_users = round(length(users_in_row)*params.user_subsampling);
        users_in_row = users_in_row(randperm(length(users_in_row), num_of_subsampled_users));
        users_ids = [users_ids, users(i) + users_in_row];
    end
    users_ids = sort(users_ids);
    num_user = length(users_ids);

% % Calculate the user IDs to be read
% num_rows=max(min(user_grids(:,2),params.active_user_last)-max(user_grids(:,1),params.active_user_first)+1,0);
% num_user=sum(num_rows.*user_grids(:,3));  % total number of users
% 
% current_grid=min(find(max(params.active_user_first,user_grids(:,2))==user_grids(:,2)));
% user_first=sum((max(min(params.active_user_first,user_grids(:,2))-user_grids(:,1)+1,0)).*user_grids(:,3))-user_grids(current_grid,3)+1;
% user_last=user_first+num_user-1;

end