% --------- DeepMIMO: A Generic Dataset for mmWave and massive MIMO ------%
% Authors: Ahmed Alkhateeb, Umut Demirhan, Abdelrahman Taha 
% Date: March 17, 2022
% Goal: Encouraging research on ML/DL for MIMO applications and
% providing a benchmarking tool for the developed algorithms
% ---------------------------------------------------------------------- %

function [channel, channel_LoS_status, path_params] = construct_DeepMIMO_channel_TD(tx_ant_size, tx_rotation, tx_FoV, tx_ant_spacing, rx_ant_size, rx_rotation, rx_FoV, rx_ant_spacing, path_params, params, params_inner)

    deg_to_rad = pi/180;

    % TX antenna parameters for a UPA structure
    M_TX_ind = antenna_channel_map(1, tx_ant_size(1), tx_ant_size(2), 0);
    M_TX=prod(tx_ant_size);
    kd_TX=2*pi*tx_ant_spacing;

    % RX antenna parameters for a UPA structure
    M_RX_ind = antenna_channel_map(1, rx_ant_size(1), rx_ant_size(2), 0);
    M_RX=prod(rx_ant_size);
    kd_RX=2*pi*rx_ant_spacing;

    if path_params.num_paths == 0
        channel = complex(zeros(M_RX, M_TX, path_params.num_paths));
        channel_LoS_status = -1;
        return
    end


    [DoD_theta, DoD_phi, DoA_theta, DoA_phi] = antenna_rotation(tx_rotation, path_params.DoD_theta, path_params.DoD_phi, rx_rotation, path_params.DoA_theta, path_params.DoA_phi);

    % Apply the radiation pattern of choice
    if params.radiation_pattern % Half-wave dipole radiation pattern
        power = path_params.power.* antenna_pattern_halfwavedipole(DoD_theta, DoD_phi) .* antenna_pattern_halfwavedipole(DoA_theta, DoA_phi);
    else % Isotropic radiation pattern
        power = path_params.power;
    end

    % Apply the FoV
    FoV_TX = antenna_FoV(DoD_theta, DoD_phi, tx_FoV);
    FoV_RX = antenna_FoV(DoA_theta, DoA_phi, rx_FoV);

    %% LoS status computation
    FoV = FoV_TX & FoV_RX;
    if sum(FoV) > 0
        channel_LoS_status = sum(path_params.LoS_status & FoV)>0;
    else
        channel = complex(zeros(M_RX, M_TX, num_sampled_subcarriers));
        channel_LoS_status = -1;
    end

    % Update the paths with FoV
    DoD_theta = DoD_theta(FoV);
    DoD_phi = DoD_phi(FoV);
    DoA_theta = DoA_theta(FoV);
    DoA_phi = DoA_phi(FoV);
    power = power(FoV);
    phase = path_params.phase(FoV);
    if params_inner.doppler_available
        Doppler_vel = path_params.Doppler_vel(FoV);
        Doppler_acc = path_params.Doppler_acc(FoV);
    end

    num_paths = sum(FoV);
    LoS_status = path_params.LoS_status(FoV);
    ToA = path_params.ToA(FoV);

    %%
    % Update path parameters based on the computed values after
    % the rotation/FoV/radiation pattern
    path_params.phase = phase;
    path_params.power = power;
    path_params.DoD_theta = DoD_theta;
    path_params.DoD_phi = DoD_phi;
    path_params.DoA_theta = DoA_theta;
    path_params.DoA_phi = DoA_phi;
    if params_inner.doppler_available
        path_params.Doppler_vel = Doppler_vel;
        path_params.Doppler_acc = Doppler_acc;
    end
    path_params.num_paths = num_paths;
    path_params.ToA = ToA;
    path_params.LoS_status = LoS_status;

    if num_paths == 0
        channel = complex(zeros(M_RX, M_TX, num_sampled_subcarriers));
        channel_LoS_status = -1;
        return
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

    %Generate the time domain (TD) impulse response where each 2D slice represents the TD channel matrix for one specific path delay
    path_const=sqrt(power).*exp(1j*path_params.phase*deg_to_rad);
    channel = reshape(array_response_RX, M_RX, 1, []) .* reshape(array_response_TX, 1, M_TX, []) .* reshape(path_const, 1, 1, path_params.num_paths);
end