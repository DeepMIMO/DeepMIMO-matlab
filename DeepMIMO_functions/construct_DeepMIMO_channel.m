% --------- DeepMIMO: A Generic Dataset for mmWave and massive MIMO ------%
% Author: Ahmed Alkhateeb
% Date: Sept. 5, 2018
% Goal: Encouraging research on ML/DL for mmWave MIMO applications and
% providing a benchmarking tool for the developed algorithms
% ---------------------------------------------------------------------- %
function [channel]=construct_DeepMIMO_channel(tx_ant_size, tx_ant_spacing, rx_ant_size, rx_ant_spacing, params_user, params)

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
M_MS_ind = antenna_channel_map(rx_ant_size(1), rx_ant_size(2), rx_ant_size(3), 0);
M_MS=prod(rx_ant_size);
kd_MS=2*pi*rx_ant_spacing;

if params_user.num_paths == 0
    channel = complex(zeros(M_MS, M, num_sampled_subcarriers));
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
        channel = sum(reshape(array_response_RX, M_MS, 1, 1, []) .* reshape(conj(array_response_TX), 1, M, 1, []) .* reshape(path_const, 1, 1, num_sampled_subcarriers, []), 4);
    otherwise
        upsampling_factor=params.pulse_upsampling_factor;
        
        conv_guard_time = max(10, cyclic_prefix); %Selected to have the smallest sidelobe amplitude from the left at least "1e-3" of the mainlobe peak
        d_ext = (-conv_guard_time:(1/upsampling_factor):cyclic_prefix+6).'; %extended d domain
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
        
        if params.activate_RX_ideal_LPF
            LPF_fn = pulse_sinc(d_ext);
        else
            LPF_fn = pulse_delta(d_ext);
        end
        
        conv_vec = zeros(length(d_ext)*2-1, params_user.num_paths, 'single');
        
        for l=1:params_user.num_paths
            conv_vec(:, l) = conv(PS_fn(:, l), LPF_fn);
        end
        
        conv_vec = conv_vec./max(abs(conv_vec), [], 1); % Normalization
        conv_vec = exp(1j*params_user.phase*ang_conv).*sqrt(power/params.num_OFDM) .* conv_vec; %Power of the paths and phase
        conv_vec = conv_vec(startpoint:upsampling_factor:endpoint, :); % Downsampling
        
        channel = sum(reshape(array_response_RX, M_MS, 1, 1, []) .* reshape(conj(array_response_TX), 1, M, 1, []) .* reshape(conv_vec, 1, 1, [], params_user.num_paths), 4);
        channel = sum(reshape(channel, M_MS, M, 1, []) .* reshape(delay_d_conv, 1, 1, num_sampled_subcarriers, []), 4);
end

end