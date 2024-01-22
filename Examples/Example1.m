%% Generate Dataset
addpath(genpath('../'))
dataset_params = read_params('Example1_params.m');

% Generate the dataset with the loaded parameters
[DeepMIMO_dataset, dataset_params] = DeepMIMO_generator(dataset_params);

%% LoS Status of the Users
%
% Plot LoS status of the users w.r.t. BS1
%
plot_los_status(DeepMIMO_dataset{1})

%
% Plot LoS status of the users w.r.t. BS1
%
plot_los_status(DeepMIMO_dataset{2})

%% Variable Inspection (BS-UE channel)
%
% Select a transmit basestation and a receive user pair.
% *Note: These variables will be used later to select a single user.*
%
TX_BS = 1; RX_User = 24331;

% Let's check the size of the dataset
size_of_BSuser_channel = size(DeepMIMO_dataset{TX_BS}.user{RX_User}.channel)

% BS-user link information
BS_user_link = DeepMIMO_dataset{TX_BS}.user{RX_User}

% Channel path information
BS_user_path_params = DeepMIMO_dataset{TX_BS}.user{RX_User}.path_params

%% Variable Inspection (BS-BS channel)
%
% Select a transmit basestation and a receive basesation pair
%
TX_BS = 1; RX_BS = 2;

% Let's check the size of the dataset
size_of_BSBS_channel = size(DeepMIMO_dataset{TX_BS}.basestation{RX_BS}.channel)

% BS-BS link information
BS_BS_link = DeepMIMO_dataset{TX_BS}.basestation{RX_BS}

% Channel path information
BS_BS_path_params = DeepMIMO_dataset{TX_BS}.basestation{RX_BS}.path_params

%% Visualization of a channel matrix

H = squeeze(DeepMIMO_dataset{TX_BS}.user{RX_User}.channel);
subcarriers = params.OFDM_sampling;
ant_ind = 1:prod(dataset_params.num_ant_BS);

figure;
imagesc(ant_ind, subcarriers, abs(H).');
xlabel('TX Antennas');
ylabel('Subcarriers');
title('Channel Magnitude Response');
colorbar;

%% Visualization of the UE positions and path-losses
bs_loc = DeepMIMO_dataset{TX_BS}.loc;
num_ue = length(DeepMIMO_dataset{TX_BS}.user); % 100 rows of 181 UEs

ue_locs = zeros(num_ue, 3);
ue_pl = zeros(num_ue, 1);
for ue_idx = 1:num_ue
    ue_locs(ue_idx, :) = DeepMIMO_dataset{TX_BS}.user{ue_idx}.loc;
    ue_pl(ue_idx) = DeepMIMO_dataset{TX_BS}.user{ue_idx}.pathloss;
end

% 3D Grid visualization with basestation
figure;
scatter3(ue_locs(:, 1), ue_locs(:, 2), ue_locs(:, 3), [], ue_pl);
hold on
scatter3(bs_loc(1), bs_loc(2), bs_loc(3), 'rx');
colorbar()
xlabel('x (m)');
ylabel('y (m)');
zlabel('z (m)');
title('Path Loss (dB)')
legend('UE', 'BS', 'Location', 'best')

% 2D Grid Visualization
figure;
scatter(ue_locs(:, 1), ue_locs(:, 2), [], ue_pl);
colorbar()
xlabel('x (m)');
ylabel('y (m)');
title('UE Grid Path Loss (dB)')
xlim([min(ue_locs(:, 1)), max(ue_locs(:, 1))])
ylim([min(ue_locs(:, 2)), max(ue_locs(:, 2))])
