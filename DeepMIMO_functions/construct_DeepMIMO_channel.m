% --------- DeepMIMO: A Generic Dataset for mmWave and massive MIMO ------%
% Authors: Ahmed Alkhateeb, Umut Demirhan, Abdelrahman Taha 
% Date: March 17, 2022
% Goal: Encouraging research on ML/DL for MIMO applications and
% providing a benchmarking tool for the developed algorithms
% ---------------------------------------------------------------------- %

function [channel]=construct_DeepMIMO_channel(tx_ant_size, tx_rotation, tx_ant_spacing, rx_ant_size, rx_rotation, rx_ant_spacing, params_user, params)

BW = params.bandwidth*1e9;
ang_conv=pi/180;
Ts=1/BW;
k=(0:params.OFDM_sampling_factor:params.OFDM_limit-1).';
num_sampled_subcarriers=length(k);

% TX antenna parameters for a UPA structure
M_TX_ind = antenna_channel_map(tx_ant_size(1), tx_ant_size(2), tx_ant_size(3), 0);
M_TX=prod(tx_ant_size);
kd_TX=2*pi*tx_ant_spacing;

% RX antenna parameters for a UPA structure
M_RX_ind = antenna_channel_map(rx_ant_size(1), rx_ant_size(2), rx_ant_size(3), 0);
M_RX=prod(rx_ant_size);
kd_RX=2*pi*rx_ant_spacing;

if params_user.num_paths == 0
    channel = complex(zeros(M_RX, M_TX, num_sampled_subcarriers));
    return
end


% Change the DoD and DoA angles based on the panel orientations
if params.activate_array_rotation
    [DoD_theta, DoD_phi, DoA_theta, DoA_phi] = axes_rotation(tx_rotation, params_user.DoD_theta, params_user.DoD_phi, rx_rotation, params_user.DoA_theta, params_user.DoA_phi);
else
    DoD_theta = params_user.DoD_theta;
    DoD_phi = params_user.DoD_phi;
    DoA_theta = params_user.DoA_theta;
    DoA_phi = params_user.DoA_phi;
end

% Apply the radiation pattern of choice
if params.radiation_pattern % Half-wave dipole radiation pattern
    power = params_user.power.* antenna_pattern_halfwavedipole(DoD_theta, DoD_phi) .* antenna_pattern_halfwavedipole(DoA_theta, DoA_phi);
else % Isotropic radiation pattern
    power = params_user.power;
end

% TX Array Response - BS
gamma_TX=+1j*kd_TX*[sind(DoD_theta).*cosd(DoD_phi);
              sind(DoD_theta).*sind(DoD_phi);
              cosd(DoD_theta)];
array_response_TX = exp(M_TX_ind*gamma_TX);

% RX Array Response - UE or BS
gamma_RX=+1j*kd_RX*[sind(DoA_theta).*cosd(DoA_phi);
                    sind(DoA_theta).*sind(DoA_phi);
                    cosd(DoA_theta)];
array_response_RX = exp(M_RX_ind*gamma_RX);

% Account only for the channel within the useful OFDM symbol duration
delay_normalized=params_user.ToA/Ts;

power(delay_normalized >= params.num_OFDM) = 0;
delay_normalized(delay_normalized>=params.num_OFDM) = params.num_OFDM;

%Assuming the pulse shaping as a dirac delta function and no receive LPF
if ~params.activate_RX_filter
    path_const=sqrt(power/params.num_OFDM).*exp(1j*params_user.phase*ang_conv).*exp(-1j*2*pi*(k/params.num_OFDM)*delay_normalized);
    channel = sum(reshape(array_response_RX, M_RX, 1, 1, []) .* reshape(array_response_TX, 1, M_TX, 1, []) .* reshape(path_const, 1, 1, num_sampled_subcarriers, []), 4);
else

    d_ext = [0:(params.num_OFDM-1)]; %extended d domain
    delay_d_conv = exp(-1j*(2*pi.*k/params.num_OFDM).*d_ext);

    % Generate the pulse function
    LP_fn = pulse_sinc(d_ext.'-delay_normalized);
    conv_vec = exp(1j*params_user.phase*ang_conv).*sqrt(power/params.num_OFDM) .* LP_fn; %Power of the paths and phase

    channel = sum(reshape(array_response_RX, M_RX, 1, 1, []) .* reshape(array_response_TX, 1, M_TX, 1, []) .* reshape(conv_vec, 1, 1, [], params_user.num_paths), 4);
    channel = sum(reshape(channel, M_RX, M_TX, 1, []) .* reshape(delay_d_conv, 1, 1, num_sampled_subcarriers, []), 4);
end

end