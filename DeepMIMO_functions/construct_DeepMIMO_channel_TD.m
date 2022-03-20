% --------- DeepMIMO: A Generic Dataset for mmWave and massive MIMO ------%
% Author: Ahmed Alkhateeb
% Date: Sept. 5, 2018
% Goal: Encouraging research on ML/DL for mmWave MIMO applications and
% providing a benchmarking tool for the developed algorithms
% ---------------------------------------------------------------------- %
function [channel]=construct_DeepMIMO_channel_TD(tx_ant_size, tx_ant_spacing, rx_ant_size, rx_ant_spacing, params_user, params)

ang_conv=pi/180;

% TX antenna parameters for a UPA structure
M_ind = antenna_channel_map(tx_ant_size(1), tx_ant_size(2), tx_ant_size(3), 0);
M=prod(tx_ant_size);
kd=2*pi*tx_ant_spacing;

% RX antenna parameters for a UPA structure
M_MS_ind = antenna_channel_map(rx_ant_size(1), rx_ant_size(2), rx_ant_size(3), 0);
M_MS=prod(rx_ant_size);
kd_MS=2*pi*rx_ant_spacing;

if params_user.num_paths == 0
    channel = complex(zeros(M_MS, M, params_user.num_paths));
    return
end

% TX Array Response - BS
gamma=-1j*kd*[sin(params_user.DoD_theta*ang_conv).*cos(params_user.DoD_phi*ang_conv);
    sin(params_user.DoD_theta*ang_conv).*sin(params_user.DoD_phi*ang_conv);
    cos(params_user.DoD_theta*ang_conv)];
array_response_TX = exp(M_ind*gamma);

% RX Array Response - MS
gamma_MS=-1j*kd_MS*[sin(params_user.DoA_theta*ang_conv).*cos(params_user.DoA_phi*ang_conv);
    sin(params_user.DoA_theta*ang_conv).*sin(params_user.DoA_phi*ang_conv);
    cos(params_user.DoA_theta*ang_conv)];
array_response_RX = exp(M_MS_ind*gamma_MS);

%Generate the time domain (TD) impulse response where each 2D slice represents the TD channel matrix for one specific path delay
path_const=sqrt(params_user.power).*exp(1j*params_user.phase*ang_conv);
channel = reshape(array_response_RX, M_MS, 1, []) .* reshape(conj(array_response_TX), 1, M, []) .* reshape(path_const, 1, 1, params_user.num_paths);

end