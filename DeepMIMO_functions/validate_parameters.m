function [params, params_inner] = validate_parameters(params)

    [params, params_inner] = additional_params(params);

    params_inner = validate_OFDM_params(params, params_inner);
end

function [params, params_inner] = additional_params(params)

    % Add dataset path
    if ~isfield(params, 'dataset_folder')
        params_inner.dataset_folder = fullfile('./Raytracing_scenarios/');

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
        params_inner.dataset_folder = fullfile(params.dataset_folder);
    end
    
    scenario_folder = fullfile(params_inner.dataset_folder, params.scenario);
    assert(logical(exist(scenario_folder, 'dir')), ['There is no scenario named "' params.scenario '" in the folder "' scenario_folder '/"' '. Please make sure the scenario name is correct and scenario files are downloaded and placed correctly.']);

    % Determine if the scenario is dynamic
    params_inner.dynamic_scenario = 0;
    if ~isempty(strfind(params.scenario, 'dyn'))
        params_inner.dynamic_scenario = 1;
        list_of_folders = strsplit(sprintf('/scene_%i/--', params.scene_first-1:params.scene_last-1),'--');
        list_of_folders(end) = [];
        list_of_folders = fullfile(params_inner.dataset_folder, params.scenario, list_of_folders);
    else
        list_of_folders = {fullfile(params_inner.dataset_folder, params.scenario)};
    end
    params_inner.list_of_folders = list_of_folders;
    
    % Read scenario parameters
    params_inner.scenario_files=fullfile(list_of_folders{1}, params.scenario); % The initial of all the scenario files
    load([params_inner.scenario_files, '.params.mat']) % Scenario parameter file

    % BS-BS channel parameters
    if params.enable_BS2BSchannels
        load([params_inner.scenario_files, '.BSBS.params.mat']) % BS2BS parameter file
        params.BS_grids = BS_grids;
    end

    params.cp_duration = floor(params.num_OFDM*params.cyclic_prefix_ratio)/(params.bandwidth*1e9);
    params.carrier_freq = carrier_freq; % in Hz
    params.transmit_power_raytracing = transmit_power; % in dBm
    params.user_grids = user_grids;
    params.num_BS = num_BS;
    params.num_active_BS =  length(params.active_BS);
    
    assert(params.row_subsampling<=1 & params.row_subsampling>0, 'Row subsampling parameters must be selected in (0, 1]')
    assert(params.user_subsampling<=1 & params.user_subsampling>0, 'User subsampling parameters must be selected in (0, 1]')

    [params.user_ids, params.num_user] = find_users(params);
end

function [params_inner] = validate_OFDM_params(params, params_inner)
    % Check UE antenna size
    ant_size = size(params.num_ant_UE);
    assert(ant_size(2) == 3, 'The defined user antenna panel size must be 3 dimensional (in x-y-z)')

    % Check BS antenna size
    ant_size = size(params.num_ant);
    assert(ant_size(2) == 3, 'The defined BS antenna panel size must be 3 dimensional (in x-y-z)')
    if ant_size(1) ~= params.num_active_BS
        if ant_size(1) == 1
            params_inner.num_ant = repmat(params.num_ant, params.num_active_BS, 1);
        else
            error('The defined BS antenna panel size must be either 1x3 or Nx3 dimensional, where N is the number of active BSs.')
        end
    else
        params_inner.num_ant = params.num_ant;
    end

    % Check BS and UE antenna array (panel) orientation
    if params.activate_array_rotation
        array_rotation_size = size(params.array_rotation);
        assert(array_rotation_size(2) == 3, 'The defined BS antenna array rotation must be 3 dimensional (rotation angles around x-y-z axes)')
        if array_rotation_size(1) ~= params.num_active_BS
            if array_rotation_size(1) == 1
                params_inner.array_rotation = repmat(params.array_rotation, params.num_active_BS, 1);
            else
                error('The defined BS antenna array rotation size must be either 1x3 or Nx3 dimensional, where N is the number of active BSs.')
            end
        else
            params_inner.array_rotation = params.array_rotation;
        end
    else
        params_inner.array_rotation = zeros(params.num_active_BS,3);
    end

    % Check UE antenna array (panel) orientation
    if params.activate_array_rotation
        array_rotation_size = size(params.array_rotation_UE);
        if array_rotation_size(1) == 1 && array_rotation_size(2) == 3
            params_inner.array_rotation_UE = repmat(params.array_rotation_UE, params.num_user, 1);
        elseif array_rotation_size(1) == 3 && array_rotation_size(2) == 2
            params_inner.array_rotation_UE = zeros(params.num_user, 3);
            for i = 1:3
                params_inner.array_rotation_UE(:, i) = unifrnd(params.array_rotation_UE(i, 1), params.array_rotation_UE(i, 2), params.num_user, 1);
            end
        else
            error('The defined user antenna array rotation size must be either 1x3 for fixed, or 3x2 for random generation.')
        end
    else
        params_inner.array_rotation_UE = zeros(params.num_user, 3);
    end
    
    
    % Check BS antenna spacing
    ant_spacing_size = length(params.ant_spacing);
    if ant_spacing_size ~= params.num_active_BS
        if ant_spacing_size == 1
            params_inner.ant_spacing = repmat(params.ant_spacing, params.num_active_BS, 1);
        else
            error('The defined BS antenna spacing must be either a scalar or an N dimensional vector, where N is the number of active BSs.')
        end
    else
        params_inner.ant_spacing = params.ant_spacing;
    end

    
end