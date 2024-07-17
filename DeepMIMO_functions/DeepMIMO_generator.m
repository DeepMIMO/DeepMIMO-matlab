% --------- DeepMIMO: A Generic Dataset for mmWave and massive MIMO ------%
% Authors: Ahmed Alkhateeb, Umut Demirhan, Abdelrahman Taha 
% Date: March 17, 2022
% Goal: Encouraging research on ML/DL for MIMO applications and
% providing a benchmarking tool for the developed algorithms
% ---------------------------------------------------------------------- %

function [DeepMIMO_dataset, params] = DeepMIMO_generator(params)

    % -------------------------- DeepMIMO Dataset Generation -----------------%
    fprintf(' DeepMIMO Dataset Generation started')

    [params, params_inner] = validate_parameters(params);

    if params_inner.dynamic_scenario
        for f = 1:length(params_inner.list_of_folders)
            fprintf('\nGenerating Scene %i/%i', f, length(params_inner.list_of_folders))
            params_inner.scene = f;
            DeepMIMO_scene{f} = generate_data(params, params_inner);
            param{f} = params;
        end

        DeepMIMO_dataset = DeepMIMO_scene;
        params = param;
    else
        if params_inner.dual_polar_available
            DeepMIMO_dataset = generate_data_polar(params, params_inner);
        else
            DeepMIMO_dataset = generate_data(params, params_inner);
        end
    end

    fprintf('\n DeepMIMO Dataset Generation completed \n')

end

function DeepMIMO_dataset = generate_data(params, params_inner)
    % Reading ray tracing data
    fprintf('\n Reading the channel parameters of the ray-tracing scenario %s', params.scenario)
    for t=1:params.num_active_BS
        bs_ID = params.active_BS(t);
        fprintf('\n Basestation %i', bs_ID);
        [TX{t}.channel_params, TX{t}.channel_params_BSBS, TX{t}.loc] = feval(params_inner.raytracing_fn, bs_ID, params, params_inner);
    end

    % Constructing the channel matrices from ray-tracing
    for t = 1:params.num_active_BS
        fprintf('\n Constructing the DeepMIMO Dataset for BS %d', params.active_BS(t))
        c = progress_counter(length(TX{t}.channel_params)+params.num_active_BS);

        % BS transmitter location & rotation
        DeepMIMO_dataset{t}.loc = TX{t}.loc;
        DeepMIMO_dataset{t}.rotation = params_inner.array_rotation_BS(t,:);

        %----- BS-User Channels
        for user=1:length(TX{t}.channel_params)
            % Channel Construction

            if params.generate_OFDM_channels
                [DeepMIMO_dataset{t}.user{user}.channel, LOS, TX{t}.channel_params(user)] = construct_DeepMIMO_channel(params_inner.num_ant_BS(t, :), params_inner.array_rotation_BS(t,:), params_inner.ant_FoV_BS(t, :), params_inner.ant_spacing_BS(t), params.num_ant_UE, params_inner.array_rotation_UE(user, :), params_inner.ant_FoV_UE, params.ant_spacing_UE, TX{t}.channel_params(user), params, params_inner);
            else
                [DeepMIMO_dataset{t}.user{user}.channel, LOS, TX{t}.channel_params(user)] = construct_DeepMIMO_channel_TD(params_inner.num_ant_BS(t, :), params_inner.array_rotation_BS(t,:), params_inner.ant_FoV_BS(t, :), params_inner.ant_spacing_BS(t), params.num_ant_UE, params_inner.array_rotation_UE(user, :), params_inner.ant_FoV_UE, params.ant_spacing_UE, TX{t}.channel_params(user), params, params_inner);
                DeepMIMO_dataset{t}.user{user}.ToA = TX{t}.channel_params(user).ToA; %Time of Arrival/Flight of each channel path (seconds)
            end
            DeepMIMO_dataset{t}.user{user}.rotation = params_inner.array_rotation_UE(user, :);

            % Location, LOS status, distance, pathloss, and channel path parameters
            DeepMIMO_dataset{t}.user{user}.loc=TX{t}.channel_params(user).loc;
            DeepMIMO_dataset{t}.user{user}.LoS_status = LOS;
            DeepMIMO_dataset{t}.user{user}.distance=TX{t}.channel_params(user).distance;
             %% TO BE UPDATED
            DeepMIMO_dataset{t}.user{user}.pathloss=TX{t}.channel_params(user).pathloss;
            
            %%
            DeepMIMO_dataset{t}.user{user}.path_params=rmfield(TX{t}.channel_params(user),{'loc','distance','pathloss'});

            c.increment();
        end

        %----- BS-BS Channels
        for BSreceiver=1:params.num_active_BS
            % Channel Construction
            if params.generate_OFDM_channels
                [DeepMIMO_dataset{t}.basestation{BSreceiver}.channel, LOS, TX{t}.channel_params_BSBS(BSreceiver)] = construct_DeepMIMO_channel(params_inner.num_ant_BS(t, :), params_inner.array_rotation_BS(t,:), params_inner.ant_FoV_BS(t, :), params_inner.ant_spacing_BS(t), params_inner.num_ant_BS(BSreceiver, :), params_inner.array_rotation_BS(BSreceiver,:), params_inner.ant_FoV_BS(BSreceiver, :), params_inner.ant_spacing_BS(BSreceiver), TX{t}.channel_params_BSBS(BSreceiver), params, params_inner);
            else
                [DeepMIMO_dataset{t}.basestation{BSreceiver}.channel, LOS, TX{t}.channel_params_BSBS(BSreceiver)]=construct_DeepMIMO_channel_TD(params_inner.num_ant_BS(t, :), params_inner.array_rotation_BS(t,:), params_inner.ant_FoV_BS(t, :), params_inner.ant_spacing_BS(t), params_inner.num_ant_BS(BSreceiver, :), params_inner.array_rotation_BS(BSreceiver,:), params_inner.ant_FoV_BS(BSreceiver, :), params_inner.ant_spacing_BS(BSreceiver), TX{t}.channel_params_BSBS(BSreceiver), params, params_inner);
                DeepMIMO_dataset{t}.basestation{BSreceiver}.ToA=TX{t}.channel_params_BSBS(BSreceiver).ToA; %Time of Arrival/Flight of each channel path (seconds)
            end
            DeepMIMO_dataset{t}.basestation{BSreceiver}.rotation = params_inner.array_rotation_BS(BSreceiver, :);

            % Location, LOS status, distance, pathloss, and channel path parameters
            DeepMIMO_dataset{t}.basestation{BSreceiver}.loc=TX{t}.channel_params_BSBS(BSreceiver).loc;
            DeepMIMO_dataset{t}.basestation{BSreceiver}.LoS_status=LOS;
            DeepMIMO_dataset{t}.basestation{BSreceiver}.distance=TX{t}.channel_params_BSBS(BSreceiver).distance;
            
            %% Update Path loss
            DeepMIMO_dataset{t}.basestation{BSreceiver}.pathloss=TX{t}.channel_params_BSBS(BSreceiver).pathloss;
            DeepMIMO_dataset{t}.basestation{BSreceiver}.path_params=rmfield(TX{t}.channel_params_BSBS(BSreceiver),{'loc','distance','pathloss'});

            c.increment();
        end
    end
end

function DeepMIMO_dataset = generate_data_polar(params, params_inner)
    % Reading ray tracing data
    fprintf('\n Reading the channel parameters of the ray-tracing scenario %s', params.scenario)
    for t=1:params.num_active_BS
        bs_ID = params.active_BS(t);
        for polarization = params_inner.polarization_list
            fprintf('\n Basestation %i', bs_ID);
            [TX{t}.channel_params, TX{t}.channel_params_BSBS, TX{t}.loc] = feval(params_inner.raytracing_fn, bs_ID, params, params_inner, polarization);

            fprintf('\n Constructing the DeepMIMO Dataset for BS %d', params.active_BS(t))
            c = progress_counter(params.num_user+params.num_active_BS);

            % BS transmitter location & rotation
            DeepMIMO_dataset{t}.loc = TX{t}.loc;
            DeepMIMO_dataset{t}.rotation = params_inner.array_rotation_BS(t,:);

            %----- BS-User Channels
            for user=1:length(TX{t}.channel_params)
                % Channel Construction
                if params.generate_OFDM_channels
                    [DeepMIMO_dataset{t}.user{user}.(strcat("channel", polarization)), LOS, TX{t}.channel_params(user)] = construct_DeepMIMO_channel(params_inner.num_ant_BS(t, :), params_inner.array_rotation_BS(t,:), params_inner.ant_FoV_BS(t, :), params_inner.ant_spacing_BS(t), params.num_ant_UE, params_inner.array_rotation_UE(user, :), params_inner.ant_FoV_UE, params.ant_spacing_UE, TX{t}.channel_params(user), params, params_inner);
                else
                    [DeepMIMO_dataset{t}.user{user}.(strcat("channel", polarization)), LOS, TX{t}.channel_params(user)] = construct_DeepMIMO_channel_TD(params_inner.num_ant_BS(t, :), params_inner.array_rotation_BS(t,:), params_inner.ant_FoV_BS(t, :), params_inner.ant_spacing_BS(t), params.num_ant_UE, params_inner.array_rotation_UE(user, :), params_inner.ant_FoV_UE, params.ant_spacing_UE, TX{t}.channel_params(user), params, params_inner);
                    DeepMIMO_dataset{t}.user{user}.ToA = TX{t}.channel_params(user).ToA; %Time of Arrival/Flight of each channel path (seconds)
                end
                DeepMIMO_dataset{t}.user{user}.rotation = params_inner.array_rotation_UE(user, :);

                % Location, LOS status, distance, pathloss, and channel path parameters
                DeepMIMO_dataset{t}.user{user}.loc=TX{t}.channel_params(user).loc;
                DeepMIMO_dataset{t}.user{user}.LoS_status = LOS;
                DeepMIMO_dataset{t}.user{user}.distance=TX{t}.channel_params(user).distance;
                 %% TO BE UPDATED
                DeepMIMO_dataset{t}.user{user}.pathloss=TX{t}.channel_params(user).pathloss;
                DeepMIMO_dataset{t}.user{user}.path_params=rmfield(TX{t}.channel_params(user),{'loc','distance','pathloss'});

                c.increment();
            end

            if ~isempty(TX{t}.channel_params_BSBS)
                %----- BS-BS Channels
                for BSreceiver=1:params.num_active_BS
                    % Channel Construction
                    if params.generate_OFDM_channels
                        [DeepMIMO_dataset{t}.basestation{BSreceiver}.(strcat("channel", polarization)), LOS, TX{t}.channel_params_BSBS(BSreceiver)] = construct_DeepMIMO_channel(params_inner.num_ant_BS(t, :), params_inner.array_rotation_BS(t,:), params_inner.ant_FoV_BS(t, :), params_inner.ant_spacing_BS(t), params_inner.num_ant_BS(BSreceiver, :), params_inner.array_rotation_BS(BSreceiver,:), params_inner.ant_FoV_BS(BSreceiver, :), params_inner.ant_spacing_BS(BSreceiver), TX{t}.channel_params_BSBS(BSreceiver), params, params_inner);
                    else
                        [DeepMIMO_dataset{t}.basestation{BSreceiver}.(strcat("channel", polarization)), LOS, TX{t}.channel_params_BSBS(BSreceiver)]=construct_DeepMIMO_channel_TD(params_inner.num_ant_BS(t, :), params_inner.array_rotation_BS(t,:), params_inner.ant_FoV_BS(t, :), params_inner.ant_spacing_BS(t), params_inner.num_ant_BS(BSreceiver, :), params_inner.array_rotation_BS(BSreceiver,:), params_inner.ant_FoV_BS(BSreceiver, :), params_inner.ant_spacing_BS(BSreceiver), TX{t}.channel_params_BSBS(BSreceiver), params, params_inner);
                        DeepMIMO_dataset{t}.basestation{BSreceiver}.ToA=TX{t}.channel_params_BSBS(BSreceiver).ToA; %Time of Arrival/Flight of each channel path (seconds)
                    end
                    DeepMIMO_dataset{t}.basestation{BSreceiver}.rotation = params_inner.array_rotation_BS(BSreceiver, :);

                    % Location, LOS status, distance, pathloss, and channel path parameters
                    DeepMIMO_dataset{t}.basestation{BSreceiver}.loc=TX{t}.channel_params_BSBS(BSreceiver).loc;
                    DeepMIMO_dataset{t}.basestation{BSreceiver}.LoS_status=LOS;
                    DeepMIMO_dataset{t}.basestation{BSreceiver}.distance=TX{t}.channel_params_BSBS(BSreceiver).distance;
                    DeepMIMO_dataset{t}.basestation{BSreceiver}.pathloss=TX{t}.channel_params_BSBS(BSreceiver).pathloss;
                    DeepMIMO_dataset{t}.basestation{BSreceiver}.path_params=rmfield(TX{t}.channel_params_BSBS(BSreceiver),{'loc','distance','pathloss'});

                    c.increment();
                end
            end
        end
    end
end