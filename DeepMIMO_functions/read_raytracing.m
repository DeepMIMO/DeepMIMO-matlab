% --------- DeepMIMO: A Generic Dataset for mmWave and massive MIMO ------%
% Author: Ahmed Alkhateeb
% Date: Sept. 5, 2018
% Goal: Encouraging research on ML/DL for mmWave MIMO applications and
% providing a benchmarking tool for the developed algorithms
% ---------------------------------------------------------------------- %
function [channel_params,channel_params_BS,BS_loc]=read_raytracing(BS_ID, params, scenario_files)
%% Loading channel parameters between current active basesation transmitter and user receivers
filename_DoD=strcat(scenario_files, '.', int2str(BS_ID),'.DoD.mat');
filename_DoA=strcat(scenario_files, '.', int2str(BS_ID),'.DoA.mat');
filename_CIR=strcat(scenario_files, '.', int2str(BS_ID),'.CIR.mat');
filename_LOS=strcat(scenario_files, '.', int2str(BS_ID),'.LoS.mat');
filename_PL=strcat(scenario_files, '.', int2str(BS_ID),'.PL.mat');
filename_Loc=strcat(scenario_files, '.Loc.mat');

DoD_array=importdata(filename_DoD);
DoA_array=importdata(filename_DoA);
CIR_array=importdata(filename_CIR);
LOS_array=importdata(filename_LOS);
PL_array=importdata(filename_PL);
Loc_array=importdata(filename_Loc);

user_ids = double(params.user_ids);
user_last = double(max(user_ids));
num_paths = double(params.num_paths);
tx_power_raytracing = double(params.transmit_power_raytracing); %The transmit power in dBm used to generate the channel data
transmit_power = 30;

total_num_users=double(DoD_array(1));
pointer=0;

DoD_array(1)=[];
DoA_array(1)=[];
CIR_array(1)=[];
LOS_array(1)=[];

channel_params_all=struct('DoD_phi',[],'DoD_theta',[],'DoA_phi',[],'DoA_theta',[],'phase',[],'ToA',[],'power',[],'num_paths',[],'loc',[],'LoS_status',[]);
channel_params_all_BS =struct('DoD_phi',[],'DoD_theta',[],'DoA_phi',[],'DoA_theta',[],'phase',[],'ToA',[],'power',[],'num_paths',[],'loc',[],'LoS_status',[]);

path_DS_violation = 0;
max_DS_violation = 0;
channel_pwr_lost = [];

user_count = 1;
for Receiver_Number=1:user_last
    max_paths=double(DoD_array(pointer+2));
    num_path_limited=double(min(num_paths,max_paths));
    if ismember(Receiver_Number, user_ids)
        if (max_paths>0)
            Relevant_data_length=max_paths*4;
            Relevant_limited_data_length=num_path_limited*4;
            
            Relevant_DoD_array=DoD_array(pointer+3:pointer+2+Relevant_data_length);
            Relevant_DoA_array=DoA_array(pointer+3:pointer+2+Relevant_data_length);
            Relevant_CIR_array=CIR_array(pointer+3:pointer+2+Relevant_data_length);
            
            channel_params_all(user_count).DoD_phi=Relevant_DoD_array(2:4:Relevant_limited_data_length);
            channel_params_all(user_count).DoD_theta=Relevant_DoD_array(3:4:Relevant_limited_data_length);
            channel_params_all(user_count).DoA_phi=Relevant_DoA_array(2:4:Relevant_limited_data_length);
            channel_params_all(user_count).DoA_theta=Relevant_DoA_array(3:4:Relevant_limited_data_length);
            channel_params_all(user_count).phase=Relevant_CIR_array(2:4:Relevant_limited_data_length);
            channel_params_all(user_count).ToA=Relevant_CIR_array(3:4:Relevant_limited_data_length);
            channel_params_all(user_count).DS = channel_params_all(user_count).ToA - min(channel_params_all(user_count).ToA);
            channel_params_all(user_count).power=1e-3*(10.^(0.1*( Relevant_CIR_array(4:4:Relevant_limited_data_length)+(transmit_power-tx_power_raytracing) )));
            channel_params_all(user_count).num_paths=num_path_limited;
            channel_params_all(user_count).loc=Loc_array(Receiver_Number,2:4);
            channel_params_all(user_count).distance=PL_array(Receiver_Number,1);
            channel_params_all(user_count).pathloss=PL_array(Receiver_Number,2);
            channel_params_all(user_count).LoS_status=LOS_array(Receiver_Number);
            
            %Cyclic prefix check for BS-user links
            max_DS = double(max(channel_params_all(user_count).DS));
            if  max_DS>= params.cp_duration
                if max_DS > max_DS_violation
                    max_DS_violation = max_DS;
                end
                path_DS_violation = path_DS_violation + 1;
                DS_vec = double(channel_params_all(user_count).DS);
                power_vec = double(channel_params_all(user_count).power);
                channel_pwr_lost=cat(1,channel_pwr_lost,sum(power_vec(DS_vec>= params.cp_duration))/sum(power_vec));
            end
            
        else
            channel_params_all(user_count).DoD_phi=[];
            channel_params_all(user_count).DoD_theta=[];
            channel_params_all(user_count).DoA_phi=[];
            channel_params_all(user_count).DoA_theta=[];
            channel_params_all(user_count).phase=[];
            channel_params_all(user_count).ToA=[];
            channel_params_all(user_count).DS=[];
            channel_params_all(user_count).power=[];
            channel_params_all(user_count).num_paths=0;
            channel_params_all(user_count).loc=Loc_array(Receiver_Number,2:4);
            channel_params_all(user_count).distance=PL_array(Receiver_Number,1);
            channel_params_all(user_count).pathloss=[];
            channel_params_all(user_count).LoS_status=LOS_array(Receiver_Number);
        end
        user_count = double(user_count + 1);
    end
    pointer=double(pointer+max_paths*4+2);
end

if path_DS_violation>0
    cp_note(BS_ID,params.cp_duration,max_DS_violation,path_DS_violation,channel_pwr_lost,0)
end

channel_params=channel_params_all(1,:);

%% Loading channel parameters between current active basesation transmitter and all the basestation receivers
if params.enable_BS2BSchannels
    filename_BSBS_DoD=strcat(scenario_files, '.', int2str(BS_ID),'.DoD.BSBS.mat');
    filename_BSBS_DoA=strcat(scenario_files, '.', int2str(BS_ID),'.DoA.BSBS.mat');
    filename_BSBS_CIR=strcat(scenario_files, '.', int2str(BS_ID),'.CIR.BSBS.mat');
    filename_BSBS_LOS=strcat(scenario_files, '.', int2str(BS_ID),'.LoS.BSBS.mat');
    filename_BSBS_PL=strcat(scenario_files, '.', int2str(BS_ID),'.PL.BSBS.mat');
    filename_BSBS_Loc=strcat(scenario_files, '.BSBS.RX_Loc.mat');
    
    DoD_BSBS_array=importdata(filename_BSBS_DoD);
    DoA_BSBS_array=importdata(filename_BSBS_DoA);
    CIR_BSBS_array=importdata(filename_BSBS_CIR);
    LOS_BSBS_array=importdata(filename_BSBS_LOS);
    PL_BSBS_array=importdata(filename_BSBS_PL);
    Loc_BSBS_array=importdata(filename_BSBS_Loc);
    
    num_paths_BSBS = double(params.num_paths);
    total_num_BSs=double(DoD_BSBS_array(1));
    BS_pointer=0;
    
    DoD_BSBS_array(1)=[];
    DoA_BSBS_array(1)=[];
    CIR_BSBS_array(1)=[];
    LOS_BSBS_array(1)=[];
    
    path_DS_violation_BS = 0;
    max_DS_violation_BS = 0;
    channel_pwr_lost_BS = [];
    
    BS_count = 1;
    for Receiver_BS_Number=1:total_num_BSs
        max_paths_BSBS=double(DoD_BSBS_array(BS_pointer+2));
        num_path_BS_limited=double(min(num_paths_BSBS,max_paths_BSBS));
        if sum(Receiver_BS_Number == double(params.active_BS)) == 1 %Only read the channels related to the active basestation receivers
            
            if (max_paths_BSBS>0)
                Relevant_data_length_BSBS=max_paths_BSBS*4;
                Relevant_limited_data_length_BSBS=num_path_BS_limited*4;
                
                Relevant_DoD_BSBS_array=DoD_BSBS_array(BS_pointer+3:BS_pointer+2+Relevant_data_length_BSBS);
                Relevant_DoA_BSBS_array=DoA_BSBS_array(BS_pointer+3:BS_pointer+2+Relevant_data_length_BSBS);
                Relevant_CIR_BSBS_array=CIR_BSBS_array(BS_pointer+3:BS_pointer+2+Relevant_data_length_BSBS);
                
                channel_params_all_BS(BS_count).DoD_phi=Relevant_DoD_BSBS_array(2:4:Relevant_limited_data_length_BSBS);
                channel_params_all_BS(BS_count).DoD_theta=Relevant_DoD_BSBS_array(3:4:Relevant_limited_data_length_BSBS);
                channel_params_all_BS(BS_count).DoA_phi=Relevant_DoA_BSBS_array(2:4:Relevant_limited_data_length_BSBS);
                channel_params_all_BS(BS_count).DoA_theta=Relevant_DoA_BSBS_array(3:4:Relevant_limited_data_length_BSBS);
                channel_params_all_BS(BS_count).phase=Relevant_CIR_BSBS_array(2:4:Relevant_limited_data_length_BSBS);
                channel_params_all_BS(BS_count).ToA=Relevant_CIR_BSBS_array(3:4:Relevant_limited_data_length_BSBS);
                channel_params_all_BS(BS_count).DS = channel_params_all_BS(BS_count).ToA - min(channel_params_all_BS(BS_count).ToA);
                channel_params_all_BS(BS_count).power=1e-3*(10.^(0.1*( Relevant_CIR_BSBS_array(4:4:Relevant_limited_data_length_BSBS)+(transmit_power-tx_power_raytracing) )));
                channel_params_all_BS(BS_count).num_paths=num_path_BS_limited;
                channel_params_all_BS(BS_count).loc=Loc_BSBS_array(Receiver_BS_Number,2:4);
                channel_params_all_BS(BS_count).distance=PL_BSBS_array(Receiver_BS_Number,1);
                channel_params_all_BS(BS_count).pathloss=PL_BSBS_array(Receiver_BS_Number,2);
                channel_params_all_BS(BS_count).LoS_status=LOS_BSBS_array(Receiver_BS_Number);
                
                %Cyclic prefix check for BS-BS links
                max_DS_BS = double(max(channel_params_all_BS(BS_count).DS));
                if  max_DS_BS>= params.cp_duration
                    if max_DS_BS > max_DS_violation_BS
                        max_DS_violation_BS = max_DS_BS;
                    end
                    path_DS_violation_BS = path_DS_violation_BS + 1;
                    DS_vec_BS = double(channel_params_all_BS(BS_count).DS);
                    power_vec_BS = double(channel_params_all_BS(BS_count).power);
                    channel_pwr_lost_BS=cat(1,channel_pwr_lost_BS,sum(power_vec_BS(DS_vec_BS>= params.cp_duration))/sum(power_vec_BS));
                end
                
            else
                channel_params_all_BS(BS_count).DoD_phi=[];
                channel_params_all_BS(BS_count).DoD_theta=[];
                channel_params_all_BS(BS_count).DoA_phi=[];
                channel_params_all_BS(BS_count).DoA_theta=[];
                channel_params_all_BS(BS_count).phase=[];
                channel_params_all_BS(BS_count).ToA=[];
                channel_params_all_BS(BS_count).DS=[];
                channel_params_all_BS(BS_count).power=[];
                channel_params_all_BS(BS_count).num_paths=0;
                channel_params_all_BS(BS_count).loc=Loc_BSBS_array(Receiver_BS_Number,2:4);
                channel_params_all_BS(BS_count).distance=PL_BSBS_array(Receiver_BS_Number,1);
                channel_params_all_BS(BS_count).pathloss=[];
                channel_params_all_BS(BS_count).LoS_status=LOS_BSBS_array(Receiver_BS_Number);
            end
            BS_count = double(BS_count + 1);
        end
        BS_pointer=double(BS_pointer+max_paths_BSBS*4+2);
    end
    
    if path_DS_violation_BS>0
        cp_note(BS_ID,params.cp_duration,max_DS_violation_BS,path_DS_violation_BS,channel_pwr_lost_BS,1)
    end
    
end
channel_params_BS=channel_params_all_BS(1,:);


%% Loading current active basestation location
TX_Loc_array=importdata(strcat(scenario_files, '.TX_Loc.mat')); %Reading transmitter locations
BS_loc = TX_Loc_array(BS_ID,2:4); %Select current active basestation location

end

function cp_note(BS_ID,cp_duration,max_DS_violation,path_DS_violation,channel_pwr_lost,basestation)
%Display a note when cyclic prefix is less than the channel tap length

fprintf('\n');
if basestation
    disp([' Note on the BS-BS links for transmit BS' num2str(BS_ID)  ':'])
else
    disp([' Note on the BS-user links for transmit BS' num2str(BS_ID)  ':'])
end
disp([' Cyclic prefix duration (' num2str(cp_duration) ' s) should be larger than the maximum channel delay spread (' num2str(max_DS_violation), ' s).'])
disp(' Any FD channel defined beyond the cyclic prefix duration will be clipped to the cyclic prefix duration.')
if basestation
    disp([' This design choice negelects ' num2str(round(mean(channel_pwr_lost)*100,2)) '% of the channel power on average for ' num2str(path_DS_violation) ' BS-BS links, with a maximum of ' num2str(round(max(channel_pwr_lost)*100,2)) '% of the channel power.'])
else
    disp([' This design choice negelects ' num2str(round(mean(channel_pwr_lost)*100,2)) '% of the channel power on average for ' num2str(path_DS_violation) ' BS-user links, with a maximum of ' num2str(round(max(channel_pwr_lost)*100,2)) '% of the channel power.'])
end
disp(' Please refer to "https://www.deepmimo.net/community/" for the recommended practice.')
end