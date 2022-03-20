function [params, list_of_folders] = validate_parameters(params)

    [params, list_of_folders] = add_additional_params(params);

    validate_data_params(params);
    
    params = validate_OFDM_params(params);
end

function [params, list_of_folders] = add_additional_params(params)

    % Add dataset path
    if ~isfield(params, 'dataset_folder')
        params.dataset_folder = fullfile('./Raytracing_scenarios/');
        
        % Create folders if not exists
        folder_one = './Raytracing_scenarios/';
        folder_two = './DeepMIMO_dataset/';
        if ~exist(folder_one, 'dir')
            mkdir(folder_one);
        end
        if ~exist(folder_two, 'dir')
            mkdir(folder_two)
        end
    else
        params.dataset_folder = fullfile(params.dataset_folder);
    end

    % Determine if the scenario is dynamic
    params.dynamic_scenario = 0;
    if ~isempty(strfind(params.scenario, 'dyn'))
        params.dynamic_scenario = 1;
        list_of_folders = strsplit(sprintf('/scene_%i/--', params.scene_first-1:params.scene_last-1),'--');
        list_of_folders(end) = [];
        list_of_folders = fullfile(params.dataset_folder, params.scenario, list_of_folders);
    else
        list_of_folders = {fullfile(params.dataset_folder, params.scenario)};
    end

    % Read scenario parameters
    params.scenario_files=fullfile(list_of_folders{1}, params.scenario); % The initial of all the scenario files
    load([params.scenario_files, '.params.mat']) % Scenario parameter file
    
    % BS-BS channel parameters
    if params.enable_BS2BSchannels
        load([params.scenario_files, '.BSBS.params.mat']) % BS2BS parameter file
        params.BS_grids = BS_grids;
    end
    
    params.cp_duration = floor(params.num_OFDM*params.cyclic_prefix_ratio)/(params.bandwidth*1e9);
    params.carrier_freq = carrier_freq; % in Hz
    params.transmit_power_raytracing = transmit_power; % in dBm
    params.user_grids = user_grids;
    params.num_BS = num_BS;
    params.num_active_BS =  length(params.active_BS);
    % Find the IDs of the selected users
    [params.user_ids, params.num_user] = find_users(params);
end

function [] = validate_data_params(params)
    scenario_folder = fullfile(params.dataset_folder, params.scenario);
    assert(logical(exist(scenario_folder, 'dir')), ['There is no scenario named "' params.scenario '" in the folder "' scenario_folder '/"' '. Please make sure the scenario name is correct and scenario files are downloaded and placed correctly!']);
end
function [params] = validate_CDL5G_params(params)
    % Polarization
    assert(params.CDL_5G.polarization == 1 | params.CDL_5G.polarization == 0, 'Polarization value should be an indicator (0 or 1)')
    
    % UE Antenna
    if params.CDL_5G.customAntenna
        params.CDL_5G.ueAntenna = params.CDL_5G.ueCustomAntenna;
    else
        params.CDL_5G.ueAntenna = params.CDL_5G.ueAntSize;
    end
    
    % BS Antenna
    if params.CDL_5G.customAntenna % Custom Antenna
        if length(params.CDL_5G.bsCustomAntenna) ~= params.num_active_BS
            if length(params.CDL_5G.bsCustomAntenna) == 1
                antenna = params.CDL_5G.bsCustomAntenna;
                params.CDL_5G.bsAntenna = cell(1, params.num_active_BS);
                for ant_idx=1:params.num_active_BS
                    params.CDL_5G.bsAntenna{ant_idx} = antenna;
                end
            else
                error('The number of defined BS custom antenna should be either single or a cell array of N custom antennas, where N is the number of active BSs.')
            end
        else
            if ~iscell(params.CDL_5G.bsCustomAntenna)
                params.CDL_5G.bsAntenna = {params.CDL_5G.bsCustomAntenna};
            else
                params.CDL_5G.bsAntenna = params.CDL_5G.bsCustomAntenna;
            end
        end 
    else % Size input
        % Check BS antenna size
        ant_size = size(params.CDL_5G.bsAntSize);
        assert(ant_size(2) == 2, 'The defined BS antenna panel size must be 2 dimensional (rows - columns)')
        if ant_size(1) ~= params.num_active_BS
            if ant_size(1) == 1
                params.CDL_5G.bsAntenna = repmat(params.CDL_5G.bsAntSize, params.num_active_BS, 1);
            else
                error('The defined BS antenna panel size must be either 1x2 or Nx2 dimensional, where N is the number of active BSs.')
            end
        else
            params.CDL_5G.bsAntenna = params.CDL_5G.bsAntSize;
        end
        if ~iscell(params.CDL_5G.bsAntenna)
            params.CDL_5G.bsAntenna = num2cell(params.CDL_5G.bsAntenna, 2);
        end
    end
    % Check BS Antenna Orientation
    ant_size = size(params.CDL_5G.bsArrayOrientation);
    assert(ant_size(2) == 2, 'The defined BS antenna orientation size must be 2 dimensional (azimuth - elevation)')
    if ant_size(1) ~= params.num_active_BS
        if ant_size(1) == 1
            params.CDL_5G.bsOrientation = repmat(params.CDL_5G.bsArrayOrientation, params.num_active_BS, 1);
        else
            error('The defined BS antenna orientation size must be either 1x2 or Nx2 dimensional, where N is the number of active BSs.')
        end
    else
        params.CDL_5G.bsOrientation = params.CDL_5G.bsArrayOrientation;
    end
    if ~iscell(params.CDL_5G.bsOrientation)
        params.CDL_5G.bsOrientation = num2cell(params.CDL_5G.bsOrientation, 2);
    end
end

function [params] = validate_OFDM_params(params)
    % Check UE antenna size
    ant_size = size(params.num_ant_MS);
    assert(ant_size(2) == 3, 'The defined user antenna panel size must be 3 dimensional (in x-y-z)')
    
    % Check BS antenna size
    ant_size = size(params.num_ant);
    assert(ant_size(2) == 3, 'The defined BS antenna panel size must be 3 dimensional (in x-y-z)')
    if ant_size(1) ~= params.num_active_BS
        if ant_size(1) == 1
            params.num_ant = repmat(params.num_ant, params.num_active_BS, 1);
        else
            error('The defined BS antenna panel size must be either 1x3 or Nx3 dimensional, where N is the number of active BSs.')
        end
    end
    
    % Check BS antenna spacing
    ant_spacing_size = length(params.ant_spacing);
    if ant_spacing_size ~= params.num_active_BS
        if ant_spacing_size == 1
            params.ant_spacing = repmat(params.ant_spacing, params.num_active_BS, 1);
        else
            error('The defined BS antenna spacing must be either a scalar or an N dimensional vector, where N is the number of active BSs.')
        end
    end
end