% --------- DeepMIMO: A Generic Dataset for mmWave and massive MIMO ------%
% Author: Ahmed Alkhateeb
% Date: Sept. 5, 2018 
% Goal: Encouraging research on ML/DL for mmWave/massive MIMO applications and
% providing a benchmarking tool for the developed algorithms
% ---------------------------------------------------------------------- %

function [DeepMIMO_dataset,params]=DeepMIMO_Dataset_Generator()

% ------  Inputs to the DeepMIMO dataset generation code ------------ % 

%------Ray-tracing scenario
params.scenario='O1_60';                % The adopted ray tracing scenarios [check the available scenarios at www.aalkhateeb.net/DeepMIMO.html]

%------DeepMIMO parameters set
%Active base stations 
params.active_BS=1;          % Includes the numbers of the active BSs (values from 1-18 for 'O1')

% Active users
params.active_user_first=1;       % The first row of the considered receivers section (check the scenario description for the receiver row map)
params.active_user_last=1;        % The last row of the considered receivers section (check the scenario description for the receiver row map)

% Number of BS Antenna 
params.num_ant_x=1;                  % Number of the UPA antenna array on the x-axis 
params.num_ant_y=8;                 % Number of the UPA antenna array on the y-axis 
params.num_ant_z=4;                  % Number of the UPA antenna array on the z-axis
                                     % Note: The axes of the antennas match the axes of the ray-tracing scenario
                              
% Antenna spacing
params.ant_spacing=.5;               % ratio of the wavelnegth; for half wavelength enter .5        

% System bandwidth
params.bandwidth=0.5;                % The bandiwdth in GHz 

% OFDM parameters
params.num_OFDM=1024;                % Number of OFDM subcarriers
params.OFDM_sampling_factor=1;   % The constructed channels will be calculated only at the sampled subcarriers (to reduce the size of the dataset)
params.OFDM_limit=64;                % Only the first params.OFDM_limit subcarriers will be considered when constructing the channels

% Number of paths
params.num_paths=15;                  % Maximum number of paths to be considered (a value between 1 and 25), e.g., choose 1 if you are only interested in the strongest path

params.saveDataset=0;
 
% -------------------------- DeepMIMO Dataset Generation -----------------%
[DeepMIMO_dataset,params]=DeepMIMO_generator(params);

end
