% --------- DeepMIMO: A Generic Dataset for mmWave and massive MIMO ------%
% Author: Ahmed Alkhateeb
% Date: Sept. 5, 2018
% Goal: Encouraging research on ML/DL for mmWave MIMO applications and
% providing a benchmarking tool for the developed algorithms
% ---------------------------------------------------------------------- %
function [channel]=construct_DeepMIMO_channel(tx_ant_size, tx_rotation, tx_ant_spacing, rx_ant_size, rx_rotation, rx_ant_spacing, params_user, params)

BW = params.bandwidth*1e9;
ang_conv=pi/180;
Ts=1/BW;
k=(0:params.OFDM_sampling_factor:params.OFDM_limit-1).';
num_sampled_subcarriers=length(k);

% TX antenna parameters for a UPA structure
M_ind = antenna_channel_map(tx_ant_size(1), tx_ant_size(2), tx_ant_size(3), 0);
M=prod(tx_ant_size);
kd=2*pi*tx_ant_spacing;

% RX antenna parameters for a UPA structure
M_UE_ind = antenna_channel_map(rx_ant_size(1), rx_ant_size(2), rx_ant_size(3), 0);
M_UE=prod(rx_ant_size);
kd_UE=2*pi*rx_ant_spacing;

if params_user.num_paths == 0
    channel = complex(zeros(M_UE, M, num_sampled_subcarriers));
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

% TX Array Response - BS
gamma=+1j*kd*[sind(DoD_theta).*cosd(DoD_phi);
              sind(DoD_theta).*sind(DoD_phi);
              cosd(DoD_theta)];
array_response_TX = exp(M_ind*gamma);

% RX Array Response - UE or BS
gamma_UE=+1j*kd_UE*[sind(DoA_theta).*cosd(DoA_phi);
                    sind(DoA_theta).*sind(DoA_phi);
                    cosd(DoA_theta)];
array_response_RX = exp(M_UE_ind*gamma_UE);

% Account only for the channel within the cyclic prefix
cyclic_prefix = floor(params.cyclic_prefix_ratio*params.num_OFDM);
delay_normalized=params_user.DS/Ts;
power = params_user.power;
power(delay_normalized>=cyclic_prefix) = 0;
delay_normalized(delay_normalized>=cyclic_prefix) = cyclic_prefix;

switch params.pulse_shaping
    case 1
        %Assuming the pulse shaping as a dirac delta function and no receive LPF
        path_const=sqrt(power/params.num_OFDM).*exp(1j*params_user.phase*ang_conv).*exp(-1j*2*pi*(k/params.num_OFDM)*delay_normalized);
        channel = sum(reshape(array_response_RX, M_UE, 1, 1, []) .* reshape(array_response_TX, 1, M, 1, []) .* reshape(path_const, 1, 1, num_sampled_subcarriers, []), 4);
    otherwise
        upsampling_factor=params.pulse_upsampling_factor;
        
        conv_guard_time = max(10, cyclic_prefix); %Selected to have the smallest sidelobe amplitude from the left at least "1e-3" of the mainlobe peak
        d_ext = (-conv_guard_time:(1/upsampling_factor):cyclic_prefix+6).'; %extended d domain
        t_0 = conv_guard_time*upsampling_factor+1;
        
        delay_d_conv = exp(-1j*(2*pi.*k/params.num_OFDM).*(0:1:(cyclic_prefix-1)));
        
        % Downsampling sample indices
        startpoint = conv_guard_time*upsampling_factor*2 + 1;
        endpoint = startpoint + cyclic_prefix*upsampling_factor - 1;
        
        % Generate the pulse function
        if params.pulse_shaping == 2 % sinc pulse
            PS_fn = pulse_sinc(d_ext-delay_normalized);
        elseif params.pulse_shaping == 3 % raised cosine pulse
            PS_fn = pulse_raised_cosine(d_ext-delay_normalized, params.rolloff_factor);
        elseif params.pulse_shaping == 4 % a user-defined pulse
            PS_fn = pulse_userdefined(d_ext-delay_normalized);
        else
            disp('Undefined pulse shaping choice');
        end
        
        conv_vec = zeros(length(d_ext)*2-1, params_user.num_paths, 'single');
        if params.activate_RX_ideal_LPF
            LPF_fn = pulse_sinc(d_ext);
            
            for l=1:params_user.num_paths
                conv_vec(:, l) = conv(PS_fn(:, l), LPF_fn);
            end
        else % Convolution with Delta Pulse
            conv_vec(t_0:end-length(d_ext)+t_0, :) = PS_fn;
        end
        
        conv_vec = conv_vec./max(abs(conv_vec), [], 1); % Normalization
        conv_vec = conv_vec(startpoint:upsampling_factor:endpoint, :); % Downsampling
        conv_vec = exp(1j*params_user.phase*ang_conv).*sqrt(power/params.num_OFDM) .* conv_vec; %Power of the paths and phase

        channel = sum(reshape(array_response_RX, M_UE, 1, 1, []) .* reshape(array_response_TX, 1, M, 1, []) .* reshape(conv_vec, 1, 1, [], params_user.num_paths), 4);
        channel = sum(reshape(channel, M_UE, M, 1, []) .* reshape(delay_d_conv, 1, 1, num_sampled_subcarriers, []), 4);
end

end