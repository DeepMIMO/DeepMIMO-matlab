% --------- DeepMIMO: A Generic Dataset for mmWave and massive MIMO ------%
% Authors: Umut Demirhan, Abdelrahman Taha, Ahmed Alkhateeb
% Date: March 17, 2022
% Goal: Encouraging research on ML/DL for MIMO applications and
% providing a benchmarking tool for the developed algorithms
% ---------------------------------------------------------------------- %

function [channel_params_user, channel_params_BS, BS_loc] = read_raytracing_v3(BS_ID, params, params_inner, channel_extension)

    if params_inner.dual_polar_available
        data_key_name = strcat('channels', channel_extension);
    else
        data_key_name = 'channels';
    end
    
    num_paths = double(params.num_paths);
    tx_power_raytracing = params.transmit_power_raytracing;  % Current TX power in dBm
    transmit_power = 30; % Target TX power in dBm (1 Watt transmit power)
    power_diff = transmit_power-tx_power_raytracing;

    if params_inner.doppler_available
        channel_params_all = struct('phase',[],'ToA',[],'power',[],'DoA_phi',[],'DoA_theta',[],'DoD_phi',[],'DoD_theta',[],'LoS_status',[],'num_paths',[],'loc',[],'distance',[],'pathloss',[],'Doppler_vel',[],'Doppler_acc',[]);
        channel_params_all_BS = struct('phase',[],'ToA',[],'power',[],'DoA_phi',[],'DoA_theta',[],'DoD_phi',[],'DoD_theta',[],'LoS_status',[],'num_paths',[],'loc',[],'distance',[],'pathloss',[],'Doppler_vel',[],'Doppler_acc',[]);
    else
        channel_params_all = struct('phase',[],'ToA',[],'power',[],'DoA_phi',[],'DoA_theta',[],'DoD_phi',[],'DoD_theta',[],'LoS_status',[],'num_paths',[],'loc',[],'distance',[],'pathloss',[]);
        channel_params_all_BS = struct('phase',[],'ToA',[],'power',[],'DoA_phi',[],'DoA_theta',[],'DoD_phi',[],'DoD_theta',[],'LoS_status',[],'num_paths',[],'loc',[],'distance',[],'pathloss',[]);
    end
    dc = duration_check(params.symbol_duration);

    scenario_folder = params_inner.list_of_folders{params_inner.scene};
    UE_files = params_inner.UE_file_split{params_inner.scene};
    
    file_idx = 1;
    file_loaded = 0;
    user_count = 1;
        
    if params_inner.dynamic_scenario
        if ~isempty(UE_files)
            params.num_user = UE_files(2, file_idx);
            filename = strcat('BS', num2str(BS_ID), '_UE_', num2str(UE_files(1, file_idx)), '-', num2str(UE_files(2, file_idx)), '.mat');
            data = importdata(fullfile(scenario_folder, filename));
            user_start = UE_files(1, file_idx);
            
            for ue_idx = 1:params.num_user
                ue_idx_file = ue_idx - user_start;
                max_paths = double(size(data.(data_key_name){ue_idx_file}.p, 2));
                num_path_limited = double(min(num_paths, max_paths));

                channel_params = data.(data_key_name){ue_idx_file}.p;
                add_info = data.rx_locs(ue_idx_file, :);
                channel_params_all(user_count) = parse_data(params_inner.doppler_available, num_path_limited, channel_params, add_info, power_diff);
                dc.add_ToA(channel_params_all(user_count).power, channel_params_all(user_count).ToA);
                
                user_count = user_count + 1;
            end
            channel_params_user = channel_params_all(1,:);
        else
            params.num_user = 0;
            channel_params_user = [];
        end
    else
        for ue_idx = params.user_ids
            % If currently not loaded
            % load the file that user is contained
            while ue_idx > UE_files(2, file_idx)
                file_idx = file_idx + 1;
                file_loaded = 0;
            end
            if ~file_loaded
                filename = strcat('BS', num2str(BS_ID), '_UE_', num2str(UE_files(1, file_idx)), '-', num2str(UE_files(2, file_idx)), '.mat');
                data = importdata(fullfile(scenario_folder, filename));
                user_start = UE_files(1, file_idx);
                file_loaded = 1;
            end

            ue_idx_file = ue_idx - user_start;
            max_paths = double(size(data.(data_key_name){ue_idx_file}.p, 2));
            num_path_limited = double(min(num_paths, max_paths));

            channel_params = data.(data_key_name){ue_idx_file}.p;
            add_info = data.rx_locs(ue_idx_file, :);
            if isfield(data, 'tx_loc')
                BS_loc = data.tx_loc;
            end
            channel_params_all(user_count) = parse_data(params_inner.doppler_available, num_path_limited, channel_params, add_info, power_diff);
            dc.add_ToA(channel_params_all(user_count).power, channel_params_all(user_count).ToA);

            user_count = user_count + 1;
        end
        channel_params_user = channel_params_all(1,:);
    end
    
    dc.print_warnings('BS', BS_ID);
    dc.reset()

    %% Loading channel parameters between current active basesation transmitter and all the active basestation receivers
    bs_count = 1;
    filename = strcat('BS', num2str(BS_ID), '_BS.mat');
    bs_filepath = fullfile(scenario_folder, filename);
    if exist(bs_filepath, 'file')
        data = importdata(bs_filepath);
        for bs_idx = params.active_BS

            max_paths = double(size(data.(data_key_name){bs_idx}.p, 2));
            num_path_limited = double(min(num_paths, max_paths));

            channel_params = data.(data_key_name){bs_idx}.p;
            add_info = data.rx_locs(bs_idx, :);

            if bs_idx == BS_ID
                BS_loc = add_info(1:3);
            end

            channel_params_all_BS(bs_count) = parse_data(params_inner.doppler_available, num_path_limited, channel_params, add_info, power_diff);
            dc.add_ToA(channel_params_all_BS(bs_count).power, channel_params_all_BS(bs_count).ToA);

            bs_count = bs_count + 1;
        end

        channel_params_BS = channel_params_all_BS(1,:);

        dc.print_warnings('BS', BS_ID);
        dc.reset()
    else
        channel_params_BS = [];
    end
end

function x = parse_data(doppler_available, num_paths, paths, info, power_diff)
    if num_paths > 0
        x.phase = paths(1, 1:num_paths);
        x.ToA = paths(2, 1:num_paths);
        x.power = 1e-3*(10.^(0.1*(paths(3, 1:num_paths) + power_diff)));
        x.DoA_phi = paths(4, 1:num_paths);
        x.DoA_theta = paths(5, 1:num_paths);
        x.DoD_phi = paths(6, 1:num_paths);
        x.DoD_theta = paths(7, 1:num_paths);
        x.LoS_status = paths(8, 1:num_paths);
        if doppler_available
            if size(paths, 1) > 8
                x.Doppler_vel = paths(9, 1:num_paths);
                x.Doppler_acc = paths(10, 1:num_paths);
            else
                x.Doppler_vel = zeros(size(x.DoD_phi));
                x.Doppler_acc = zeros(size(x.DoD_phi));
            end
        end
    else
        x.phase = [];
        x.ToA = [];
        x.power = [];
        x.DoA_phi = [];
        x.DoA_theta = [];
        x.DoD_phi = [];
        x.DoD_theta = [];
        x.LoS_status = [];
        if doppler_available
            x.Doppler_vel = [];
            x.Doppler_acc = [];
        end
    end

    %add_info = data.rx_locs(ue_idx_file, :);
    x.num_paths = num_paths;
    x.loc = info(1:3);
    x.distance = info(4);
    x.pathloss = info(5);
end
