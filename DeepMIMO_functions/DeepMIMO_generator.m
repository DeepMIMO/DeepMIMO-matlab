% --------- DeepMIMO: A Generic Dataset for mmWave and massive MIMO ------%
% Author: Ahmed Alkhateeb
% Date: Sept. 5, 2018
% Goal: Encouraging research on ML/DL for mmWave MIMO applications and
% providing a benchmarking tool for the developed algorithms
% ---------------------------------------------------------------------- %
function [DeepMIMO_dataset, params]=DeepMIMO_generator(params)

% -------------------------- DeepMIMO Dataset Generation -----------------%
fprintf(' DeepMIMO Dataset Generation started')

[params, list_of_folders] = validate_parameters(params);

if params.dynamic_scenario
    for f = 1:length(list_of_folders)
        fprintf('\nGenerating Scene %i/%i', f, length(list_of_folders))
        params.scenario_files = fullfile(list_of_folders{f}, params.scenario); % The initial of all the scenario files
        DeepMIMO_scene{f} = generate_data(params);
        param{f} = params;
    end
    
    DeepMIMO_dataset = DeepMIMO_scene;
    params = param;
    saveDataset = params{1}.saveDataset;
else
    DeepMIMO_dataset = generate_data(params);
    saveDataset = params.saveDataset;
end

% Saving the data
if saveDataset
    fprintf('\n Saving the DeepMIMO Dataset ...')
    sfile_DeepMIMO=strcat('./DeepMIMO_dataset/DeepMIMO_dataset.mat');
    save(sfile_DeepMIMO,'DeepMIMO_dataset', 'params', '-v7.3');
end

fprintf('\n DeepMIMO Dataset Generation completed \n')

end

function DeepMIMO_dataset = generate_data(params)
% Reading ray tracing data
fprintf('\n Reading the channel parameters of the ray-tracing scenario %s', params.scenario)
for t=1:params.num_active_BS
    bs_ID = params.active_BS(t);
    fprintf('\n Basestation %i', bs_ID);
    [TX{t}.channel_params,TX{t}.channel_params_BSBS,TX{t}.loc]=read_raytracing(bs_ID, params);
end

% Constructing the channel matrices from ray-tracing
for t = 1:params.num_active_BS
    fprintf('\n Constructing the DeepMIMO Dataset for BS %d', params.active_BS(t))
    c = progress_counter(params.num_user+params.enable_BS2BSchannels*params.num_active_BS);
    
    % BS transmitter location
    DeepMIMO_dataset{t}.loc=TX{t}.loc;
    
    %----- BS-User Channels
    for user=1:params.num_user
        % Channel Construction
        if params.activate_FD_channels
            [DeepMIMO_dataset{t}.user{user}.channel]=construct_DeepMIMO_channel(params.num_ant(t, :), params.ant_spacing(t), params.num_ant_MS, params.ant_spacing_MS, TX{t}.channel_params(user), params);
        else
            [DeepMIMO_dataset{t}.user{user}.channel]=construct_DeepMIMO_channel_TD(params.num_ant(t, :), params.ant_spacing(t), params.num_ant_MS, params.ant_spacing_MS, TX{t}.channel_params(user), params);
            DeepMIMO_dataset{t}.user{user}.ToA=TX{t}.channel_params(user).ToA; %Time of Arrival/Flight of each channel path (seconds)
            DeepMIMO_dataset{t}.user{user}.DS=TX{t}.channel_params(user).DS; %Delay spread of each channel path (seconds)
        end
        % Location, LOS status, distance, pathloss, and channel path parameters
        DeepMIMO_dataset{t}.user{user}.loc=TX{t}.channel_params(user).loc;
        DeepMIMO_dataset{t}.user{user}.LoS_status=TX{t}.channel_params(user).LoS_status;
        DeepMIMO_dataset{t}.user{user}.distance=TX{t}.channel_params(user).distance;
        DeepMIMO_dataset{t}.user{user}.pathloss=TX{t}.channel_params(user).pathloss;
        DeepMIMO_dataset{t}.user{user}.path_params=rmfield(TX{t}.channel_params(user),{'loc','distance','pathloss'});
        
        c.increment();
    end
    
    %----- BS-BS Channels
    if params.enable_BS2BSchannels
        for BSreceiver=1:params.num_active_BS
            % Channel Construction
            if params.activate_FD_channels
                [DeepMIMO_dataset{t}.basestation{BSreceiver}.channel]=construct_DeepMIMO_channel(params.num_ant(t, :), params.ant_spacing(t), params.num_ant(BSreceiver, :), params.ant_spacing(BSreceiver), TX{t}.channel_params_BSBS(BSreceiver), params);
            else
                [DeepMIMO_dataset{t}.basestation{BSreceiver}.channel]=construct_DeepMIMO_channel_TD(params.num_ant(t, :), params.ant_spacing(t), params.num_ant(BSreceiver, :), params.ant_spacing(BSreceiver), TX{t}.channel_params_BSBS(BSreceiver), params);
                DeepMIMO_dataset{t}.basestation{BSreceiver}.ToA=TX{t}.channel_params_BSBS(BSreceiver).ToA; %Time of Arrival/Flight of each channel path (seconds)
                DeepMIMO_dataset{t}.basestation{BSreceiver}.DS=TX{t}.channel_params_BSBS(BSreceiver).DS; %Delay spread of each channel path (seconds)
            end
            
            % Location, LOS status, distance, pathloss, and channel path parameters
            DeepMIMO_dataset{t}.basestation{BSreceiver}.loc=TX{t}.channel_params_BSBS(BSreceiver).loc;
            DeepMIMO_dataset{t}.basestation{BSreceiver}.LoS_status=TX{t}.channel_params_BSBS(BSreceiver).LoS_status;
            DeepMIMO_dataset{t}.basestation{BSreceiver}.distance=TX{t}.channel_params_BSBS(BSreceiver).distance;
            DeepMIMO_dataset{t}.basestation{BSreceiver}.pathloss=TX{t}.channel_params_BSBS(BSreceiver).pathloss;
            DeepMIMO_dataset{t}.basestation{BSreceiver}.path_params=rmfield(TX{t}.channel_params_BSBS(BSreceiver),{'loc','distance','pathloss'});
            
            c.increment();
        end
    end
end

end