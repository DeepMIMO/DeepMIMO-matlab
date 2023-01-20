% --------- DeepMIMO: A Generic Dataset for mmWave and massive MIMO ------%
% Authors: Umut Demirhan, Abdelrahman Taha, Ahmed Alkhateeb
% Date: March 17, 2022
% Goal: Encouraging research on ML/DL for MIMO applications and
% providing a benchmarking tool for the developed algorithms
% ---------------------------------------------------------------------- %

function [channel_params_user, channel_params_BS, BS_loc]=read_raytracing_new(BS_ID, params, scenario_files, comm)
%% Loading channel parameters between current active basesation transmitter and user receivers

% Load the scenario files
BS_ID_map = params.BS_ID_map;
%%% user_ID_map = params.user_ID_map;

filename_BSBS_all = strcat(scenario_files,'_TX', int2str(BS_ID_map(BS_ID,2)),'.mat'); %%%%&&&&%%%%
channels = importdata(filename_BSBS_all);
%%% total_num_BSs = size(BS_ID_map,1);
num_paths = double(params.num_paths);
tx_power_raytracing = params.transmit_power_raytracing;  % Current TX power in dBm
transmit_power = 30; % Target TX power in dBm (1 Watt transmit power)

channel_params_all =struct('DoD_phi',[],'DoD_theta',[],'DoA_phi',[],'DoA_theta',[],'phase',[],'ToA',[],'power',[],'num_paths',[],'loc',[],'LoS_status',[]);
channel_params_all_BS =struct('DoD_phi',[],'DoD_theta',[],'DoA_phi',[],'DoA_theta',[],'phase',[],'ToA',[],'power',[],'num_paths',[],'loc',[],'LoS_status',[]);
if comm
    dc = duration_check(params.symbol_duration);
end
% Current active TX BS location
BS_loc = channels{1}.tx_loc;

% active user indices
all_BS_RX_indices=zeros(1,size(BS_ID_map,1));
BS_RX_ID = BS_ID_map(:,1);
channels_ID = 1:1:numel(channels);
for bb = 1:1:numel(BS_RX_ID)
    current_ID_vector = [BS_ID_map(BS_ID,2) BS_ID_map(BS_RX_ID(bb),2) BS_ID_map(BS_ID,3) BS_ID_map(BS_RX_ID(bb),3)];
    for cc= channels_ID
        Temp = double([channels{cc}.TX_ID,channels{cc}.RX_ID,channels{cc}.TX_ID_s,channels{cc}.RX_ID_s]);
        if ~sum(Temp - current_ID_vector)
            all_BS_RX_indices(bb) = cc;
        end
    end
end

if comm
    active_user_RX_indices = setdiff(channels_ID,all_BS_RX_indices);

    user_count = 1;
    for Receiver_user_index= active_user_RX_indices
        max_paths = double(numel(channels{Receiver_user_index}.paths.phase));
        num_path_limited=double(min(num_paths,max_paths));

        if (max_paths>0)
            channel_params = channels{Receiver_user_index}.paths;
            channel_params_all(user_count).DoD_phi=channel_params.DoD_phi(1:num_path_limited);
            channel_params_all(user_count).DoD_theta=channel_params.DoD_theta(1:num_path_limited);
            channel_params_all(user_count).DoA_phi=channel_params.DoA_phi(1:num_path_limited);
            channel_params_all(user_count).DoA_theta=channel_params.DoA_theta(1:num_path_limited);
            channel_params_all(user_count).phase=channel_params.phase(1:num_path_limited);
            channel_params_all(user_count).ToA=channel_params.ToA(1:num_path_limited);
            channel_params_all(user_count).power=1e-3*(10.^(0.1*(channel_params.power(1:num_path_limited) +(transmit_power-tx_power_raytracing))));
            channel_params_all(user_count).Doppler_vel=channel_params.Doppler_vel(1:num_path_limited);
            channel_params_all(user_count).Doppler_acc=channel_params.Doppler_acc(1:num_path_limited);
            channel_params_all(user_count).num_paths=num_path_limited;
            channel_params_all(user_count).loc=channels{Receiver_user_index}.rx_loc;
            channel_params_all(user_count).distance=channels{Receiver_user_index}.dist;
            channel_params_all(user_count).pathloss=channels{Receiver_user_index}.PL;
            channel_params_all(user_count).LoS_status=channels{Receiver_user_index}.LOS_status;

            if comm
                dc.add_ToA(channel_params_all(user_count).power, channel_params_all(user_count).ToA);
            end

        else
            channel_params_all(user_count).DoD_phi=[];
            channel_params_all(user_count).DoD_theta=[];
            channel_params_all(user_count).DoA_phi=[];
            channel_params_all(user_count).DoA_theta=[];
            channel_params_all(user_count).phase=[];
            channel_params_all(user_count).ToA=[];
            channel_params_all(user_count).power=[];
            channel_params_all(user_count).Doppler_vel=[];
            channel_params_all(user_count).Doppler_acc=[];
            channel_params_all(user_count).num_paths=0;
            channel_params_all(user_count).loc=channels{Receiver_user_index}.rx_loc;
            channel_params_all(user_count).distance=channels{Receiver_user_index}.dist;
            channel_params_all(user_count).pathloss=[];
            channel_params_all(user_count).LoS_status=channels{Receiver_user_index}.LOS_status;
        end
        user_count = double(user_count + 1);
    end

    if ~isempty(active_user_RX_indices)
        channel_params_user=channel_params_all(1,:);
    else 
        channel_params_user=struct([]);
    end
else
    channel_params_user=struct([]);
end
%% Loading channel parameters between current active basesation transmitter and all the active basestation receivers
if ~comm || params.enable_BS2BSchannels
    
    active_BS_RX_indices=zeros(1,numel(params.active_BS));
    BS_RX_ID = params.active_BS;
    for bb = 1:1:numel(BS_RX_ID)
        current_ID_vector = [BS_ID_map(BS_ID,2) BS_ID_map(BS_RX_ID(bb),2) BS_ID_map(BS_ID,3) BS_ID_map(BS_RX_ID(bb),3)];
        for cc= channels_ID
            Temp = double([channels{cc}.TX_ID,channels{cc}.RX_ID,channels{cc}.TX_ID_s,channels{cc}.RX_ID_s]);
            if ~sum(Temp - current_ID_vector)
                active_BS_RX_indices(bb) = cc;
            end
        end
    end
    
    BS_count = 1;
    for Receiver_BS_index= active_BS_RX_indices
        max_paths = double(numel(channels{Receiver_BS_index}.paths.phase));
        num_path_limited=double(min(num_paths,max_paths));
        
        if (max_paths>0)
            channel_params = channels{Receiver_BS_index}.paths;
            channel_params_all_BS(BS_count).DoD_phi=channel_params.DoD_phi(1:num_path_limited);
            channel_params_all_BS(BS_count).DoD_theta=channel_params.DoD_theta(1:num_path_limited);
            channel_params_all_BS(BS_count).DoA_phi=channel_params.DoA_phi(1:num_path_limited);
            channel_params_all_BS(BS_count).DoA_theta=channel_params.DoA_theta(1:num_path_limited);
            channel_params_all_BS(BS_count).phase=channel_params.phase(1:num_path_limited);
            channel_params_all_BS(BS_count).ToA=channel_params.ToA(1:num_path_limited);
            channel_params_all_BS(BS_count).power=1e-3*(10.^(0.1*(channel_params.power(1:num_path_limited) +(transmit_power-tx_power_raytracing))));
            channel_params_all_BS(BS_count).Doppler_vel=channel_params.Doppler_vel(1:num_path_limited);
            channel_params_all_BS(BS_count).Doppler_acc=channel_params.Doppler_acc(1:num_path_limited);
            channel_params_all_BS(BS_count).num_paths=num_path_limited;
            channel_params_all_BS(BS_count).loc=channels{Receiver_BS_index}.rx_loc;
            channel_params_all_BS(BS_count).distance=channels{Receiver_BS_index}.dist;
            channel_params_all_BS(BS_count).pathloss=channels{Receiver_BS_index}.PL;
            channel_params_all_BS(BS_count).LoS_status=channels{Receiver_BS_index}.LOS_status;
            
            if comm
                dc.add_ToA(channel_params_all_BS(BS_count).power, channel_params_all_BS(BS_count).ToA);
            end
        else
            channel_params_all_BS(BS_count).DoD_phi=[];
            channel_params_all_BS(BS_count).DoD_theta=[];
            channel_params_all_BS(BS_count).DoA_phi=[];
            channel_params_all_BS(BS_count).DoA_theta=[];
            channel_params_all_BS(BS_count).phase=[];
            channel_params_all_BS(BS_count).ToA=[];
            channel_params_all_BS(BS_count).power=[];
            channel_params_all_BS(BS_count).Doppler_vel=[];
            channel_params_all_BS(BS_count).Doppler_acc=[];
            channel_params_all_BS(BS_count).num_paths=0;
            channel_params_all_BS(BS_count).loc=channels{Receiver_BS_index}.rx_loc;
            channel_params_all_BS(BS_count).distance=channels{Receiver_BS_index}.dist;
            channel_params_all_BS(BS_count).pathloss=[];
            channel_params_all_BS(BS_count).LoS_status=channels{Receiver_BS_index}.LOS_status;
        end
        BS_count = double(BS_count + 1);
    end
    if comm
        dc.print_warnings('BS', BS_ID);
        dc.reset()
    end
end

channel_params_BS=channel_params_all_BS(1,:);

end