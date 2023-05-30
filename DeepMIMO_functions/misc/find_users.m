% --------- DeepMIMO: A Generic Dataset for mmWave and massive MIMO ------%
% Authors: Ahmed Alkhateeb, Umut Demirhan, Abdelrahman Taha
% Date: March 17, 2022
% Goal: Encouraging research on ML/DL for MIMO applications and
% providing a benchmarking tool for the developed algorithms
% ---------------------------------------------------------------------- %

function [users_ids, num_user] = find_users(params)

    rng(5); % For reproducibility with the same parameters
    
    user_grids = params.user_grids;
    start_of_grids = user_grids(:, 1);
    end_of_grids = user_grids(:, 2);
    users_per_row = user_grids(:, 3);
    if size(user_grids,2) == 4
        grids_orientation = user_grids(:, 4); % 0: The user row is defined parallel to x-axis
                                              % 1: The user row is defined parallel to y-axis
        num_of_grid_rows = ((end_of_grids-start_of_grids)+1);
    else
        grids_orientation = zeros(size(user_grids,1),1);
    end
    
    users_per_grid = ((end_of_grids-start_of_grids)+1).*users_per_row;
    rows =  params.active_user_first:params.active_user_last;
    num_of_subsampled_rows = round(length(rows)*params.row_subsampling);
    assert(num_of_subsampled_rows>=1, 'At least 1 row of users should be sampled! Please increase row subsampling rate.');
    
    rows = sort(rows(randperm(length(rows),num_of_subsampled_rows)));
    prev_grids = rows > end_of_grids;
    id_from_prev_grids = sum(prev_grids .* users_per_grid, 1);
    curr_grids = rows >= start_of_grids & rows <= end_of_grids;
    
    id_from_curr_grids_0 = sum((rows - start_of_grids).*curr_grids.*users_per_row, 1); %Assume all orientations = 0
    id_from_curr_grids_1 = sum((rows - start_of_grids).*curr_grids, 1); %Assume all orientations = 1
    id_from_curr_grids = (((grids_orientation.')*curr_grids).*id_from_curr_grids_1) + ((((1-grids_orientation).')*curr_grids).*id_from_curr_grids_0);
    
    users = sum(id_from_prev_grids + id_from_curr_grids, 1);
    row_select = nonzeros(curr_grids.*users_per_row);
    row_orientation = (grids_orientation.')*curr_grids;
    users_ids = [];
    if size(user_grids,2) == 4 %Used only when an orientation flag = 1
        step_select_1 =  nonzeros(curr_grids.*num_of_grid_rows); 
    end
    for i=1:length(row_select)
        if ~row_orientation(i) %Orientation flag = 0
            users_in_row = 1:1:row_select(i);
        else %Orientation flag = 1
            users_in_row = ( step_select_1(i)*( (1:1:row_select(i)) -1) ) +1;
        end
        num_of_subsampled_users = round(length(users_in_row)*params.user_subsampling);
        users_in_row = sort(users_in_row(randperm(length(users_in_row), num_of_subsampled_users)));
        users_ids = [users_ids, users(i) + users_in_row];
    end
    num_user = length(users_ids);

end