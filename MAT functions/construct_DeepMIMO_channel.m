% --------- DeepMIMO: A Generic Dataset for mmWave and massive MIMO ------%
% Author: Ahmed Alkhateeb
% Date: Sept. 5, 2018 
% Goal: Encouraging research on ML/DL for mmWave MIMO applications and
% providing a benchmarking tool for the developed algorithms
% ---------------------------------------------------------------------- %
function [channel]=construct_DeepMIMO_channel(params,num_ant_x,num_ant_y,num_ant_z,BW,...
    ofdm_num_subcarriers,output_subcarrier_downsampling_factor,output_subcarrier_limit,antenna_spacing_wavelength_ratio)

kd=2*pi*antenna_spacing_wavelength_ratio;
ang_conv=pi/180;
Ts=1/BW;

Mx_Ind=0:1:num_ant_x-1;
My_Ind=0:1:num_ant_y-1;
Mz_Ind=0:1:num_ant_z-1;
Mxx_Ind=repmat(Mx_Ind,1,num_ant_y*num_ant_z)';
Myy_Ind=repmat(reshape(repmat(My_Ind,num_ant_x,1),1,num_ant_x*num_ant_y),1,num_ant_z)';
Mzz_Ind=reshape(repmat(Mz_Ind,num_ant_x*num_ant_y,1),1,num_ant_x*num_ant_y*num_ant_z)';
M=num_ant_x*num_ant_y*num_ant_z; 

k=0:output_subcarrier_downsampling_factor:output_subcarrier_limit-1;
num_sampled_subcarriers=length(k); 
channel=zeros(M,num_sampled_subcarriers); 

for l=1:1:params.num_paths
    gamma_x=1j*kd*sin(params.DoD_theta(l)*ang_conv)*cos(params.DoD_phi(l)*ang_conv);
    gamma_y=1j*kd*sin(params.DoD_theta(l)*ang_conv)*sin(params.DoD_phi(l)*ang_conv);
    gamma_z=1j*kd*cos(params.DoD_theta(l)*ang_conv);
    gamma_comb=Mxx_Ind*gamma_x+Myy_Ind*gamma_y + Mzz_Ind*gamma_z;
    array_response=exp(gamma_comb);
    delay_normalized=params.ToA(l)/Ts;
    power = params.power(l).* antenna_pattern(params.DoD_theta(l), params.DoD_phi(l)) .* antenna_pattern(params.DoA_theta(l), params.DoA_phi(l)); % Apply the half-wave dipole radiation pattern for backward compatibility with the published papers
    channel=channel+array_response*sqrt(power/ofdm_num_subcarriers)*exp(1j*params.phase(l)*ang_conv)*exp(-1j*2*pi*(k/ofdm_num_subcarriers)*delay_normalized);     
end 

end