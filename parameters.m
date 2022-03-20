%Ray-tracing scenario
params.scenario= 'O1_60';           % The adopted ray tracing scenarios [check the available scenarios at www.aalkhateeb.net/DeepMIMO.html]

%Dynamic Scenario Scenes
params.scene_first = 1;
params.scene_last = 1;

%%%% DeepMIMO parameters set %%%%
% Active base stations
params.active_BS = [1, 2];                 % Includes the numbers of the active BSs (values from 1-18 for 'O1')

% Active users
params.active_user_first = 1;       % The first row of the considered receivers section (check the scenario description for the receiver row map)
params.active_user_last = 1;        % The last row of the considered receivers section (check the scenario description for the receiver row map)

% Subsampling of active users
% Setting both subsampling parameters to 1 activate all the users indicated previously
params.row_subsampling = 1;         % Randomly select round(row_subsampling*(active_user_last-params.active_user_first)) rows
params.user_subsampling = 1;        % Randomly select round(user_subsampling*number_of_users_in_row) users in each row

% Antenna array dimensions
params.num_ant=[1, 8, 4];         % Number of the UPA antenna array on the x,y,z-axes for the active BSs
% To define different size for multiple active BSs, set a matrix of
% number of active BSs x 3. 
% For 2 active BSs, it can be set by
% params.num_ant=[[1, 8, 4]
%                [1, 4, 4]];

params.num_ant_UE=[1, 4, 2];      % Number of the UPA antenna array on the x,y,z-axes for the active users

% Antenna array orientations
params.activate_array_rotation = 0;
params.array_rotation = [5, 10, 20];         
% 3D rotation angles in degrees around x,y,z-axes respectively
% The rotations around x,y,z are also called as slant, downtilt, and
% bearing angles (of an antenna towards +x)
% The origin of these rotations is the BS position (the position of the first antenna element)
% The rotation sequence applied: (a) rotate around z-axis, then (b) rotate around y-axis, then (c) rotate around x-axis. 
% To define different orientations for multiple active BSs, set a matrix of
% number of active BSs x 3. 
% For 2 active BSs, it can be set by
% params.array_rotation=[[10, 30, 45]
%                [0, 30, 0]];

params.array_rotation_UE = [0, 30, 0];      
% User antenna orientation settings
% For uniform random selection in
% [x_min, x_max], [y_min, y_max], [z_min, z_max]
% set [[x_min, x_max]; [y_min, y_max]; [z_min, z_max]]
% params.array_rotation_UE = [[0, 30]; [30, 60]; [60, 90]]; 

% Antenna spacing
params.ant_spacing=.5;              % ratio of the wavelength; for half wavelength enter .5
params.ant_spacing_UE=.5;           % ratio of the wavelength; for half wavelength enter .5

% System parameters
params.enable_BS2BSchannels=1;      % Enable (1) or disable (0) generation of the channels between basestations
params.bandwidth=0.05;              % The bandwidth in GHz
params.pulse_shaping=1;             % Pulse shaping choices: (1) No pulse shaping and matched filter,
                                    % (2) sinc pulse shaping and matched filter, (3) raised cosine pulse shaping and matched filter,
                                    % (4) user-defined pulse shaping and matched filter (Please edit the code in .\DeepMIMO_functions\userdefined_pulse.m).
params.activate_RX_ideal_LPF = 0;   % Activate receive ideal LPF for pulse shaping choices 2, 3, and 4.
params.rolloff_factor=0.05;          % Raised cosine rolloff factor (a value between 0 and 1)
params.pulse_upsampling_factor = 100;% Upsampling factor for generating sinc or raised cosine pulses

% Channel parameters
params.activate_FD_channels = 0;    % 1: activate frequency domain (FD) channel generation for OFDM systems
                                    % 0: activate instead time domain (TD) channel impulse response generation for non-OFDM systems
params.num_paths=15;                % Maximum number of paths to be considered (a value between 1 and 25), e.g., choose 1 if you are only interested in the strongest path

% if params.activate_FD_channels == 1
% OFDM parameters
params.num_OFDM=512;                % Number of OFDM subcarriers
params.OFDM_sampling_factor=1;      % The constructed channels will be calculated only at the sampled subcarriers (to reduce the size of the dataset)
params.OFDM_limit=64;               % Only the first params.OFDM_limit subcarriers will be considered when constructing the channels
params.cyclic_prefix_ratio=0.125;   % Cyclic prefix ratio from the OFDM symbol length. The OFDM symbol length = params.num_OFDM.

params.saveDataset=0;