% --------- DeepMIMO: A Generic Dataset for mmWave and massive MIMO ------%
% Authors: Ahmed Alkhateeb, Umut Demirhan, Abdelrahman Taha 
% Date: March 17, 2022
% Goal: Encouraging research on ML/DL for MIMO applications and
% providing a benchmarking tool for the developed algorithms
% ---------------------------------------------------------------------- %

function [params, params_inner] = validate_parameters(params)

    [params] = compare_with_default_params(params);
    
    [params, params_inner] = additional_params(params);

    params_inner = validate_OFDM_params(params, params_inner);
end

function [params, params_inner] = additional_params(params)

    % Add dataset path
    if ~isfield(params, 'dataset_folder')
        current_folder = mfilename('fullpath');
        deepmimo_folder = fileparts(fileparts(current_folder));
        params_inner.dataset_folder = fullfile(deepmimo_folder, '/Raytracing_scenarios/');

        % Create folders if not exists
        folder_one = fullfile(deepmimo_folder, '/Raytracing_scenarios/');
        folder_two = fullfile(deepmimo_folder, '/DeepMIMO_dataset/');
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

    params.symbol_duration = (params.num_OFDM) / (params.bandwidth*1e9);
    params.carrier_freq = carrier_freq; % in Hz
    params.transmit_power_raytracing = transmit_power; % in dBm
    params.user_grids = user_grids;
    params.num_BS = num_BS;
    params.num_active_BS =  length(params.active_BS);
    
    assert(params.row_subsampling<=1 & params.row_subsampling>0, 'Row subsampling parameters must be selected in (0, 1]')
    assert(params.user_subsampling<=1 & params.user_subsampling>0, 'User subsampling parameters must be selected in (0, 1]')

    [params.user_ids, params.num_user] = find_users(params);
end

% Check the validity of the given parameters
% Add default parameters if they don't exist in the current file
function [params] = compare_with_default_params(params)
    default_params = read_params('default_parameters.m');
    default_fields = fieldnames(default_params);
    fields = fieldnames(params);
    default_fields_exist = zeros(1, length(default_fields));
    for i = 1:length(fields)
        comp = strcmp(fields{i}, default_fields);
        if sum(comp) == 1
            default_fields_exist(comp) = 1;
        else
            if ~strcmp(fields{i}, "dataset_folder")
                fprintf('\nThe parameter "%s" defined in the given parameters is not used by DeepMIMO', fields{i}) 
            end
        end
    end
    default_fields_exist = ~default_fields_exist;
    default_nonexistent_fields = find(default_fields_exist);
    for i = 1:length(default_nonexistent_fields)
        field = default_fields{default_nonexistent_fields(i)};
        value = getfield(default_params, field);
        params = setfield(params, field, value);
        % fprintf('\nAdding default parameter: %s - %s', field, num2str(value)) 
    end
end

function [params_inner] = validate_OFDM_params(params, params_inner)
    % Check UE antenna size
    ant_size = size(params.num_ant_UE);
    assert(ant_size(2) == 3, 'The defined user antenna panel size must be 3 dimensional (in x-y-z)')

    % Check BS antenna size
    ant_size = size(params.num_ant_BS);
    assert(ant_size(2) == 3, 'The defined BS antenna panel size must be 3 dimensional (in x-y-z)')
    if ant_size(1) ~= params.num_active_BS
        if ant_size(1) == 1
            params_inner.num_ant_BS = repmat(params.num_ant_BS, params.num_active_BS, 1);
        else
            error('The defined BS antenna panel size must be either 1x3 or Nx3 dimensional, where N is the number of active BSs.')
        end
    else
        params_inner.num_ant_BS = params.num_ant_BS;
    end

    % Check BS and UE antenna array (panel) orientation
    if params.activate_array_rotation
        array_rotation_size = size(params.array_rotation_BS);
        assert(array_rotation_size(2) == 3, 'The defined BS antenna array rotation must be 3 dimensional (rotation angles around x-y-z axes)')
        if array_rotation_size(1) ~= params.num_active_BS
            if array_rotation_size(1) == 1
                params_inner.array_rotation_BS = repmat(params.array_rotation_BS, params.num_active_BS, 1);
            else
                error('The defined BS antenna array rotation size must be either 1x3 or Nx3 dimensional, where N is the number of active BSs.')
            end
        else
            params_inner.array_rotation_BS = params.array_rotation_BS;
        end
    else
        params_inner.array_rotation_BS = zeros(params.num_active_BS,3);
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
    ant_spacing_size = length(params.ant_spacing_BS);
    if ant_spacing_size ~= params.num_active_BS
        if ant_spacing_size == 1
            params_inner.ant_spacing_BS = repmat(params.ant_spacing_BS, params.num_active_BS, 1);
        else
            error('The defined BS antenna spacing must be either a scalar or an N dimensional vector, where N is the number of active BSs.')
        end
    else
        params_inner.ant_spacing_BS = params.ant_spacing_BS;
    end

    
end