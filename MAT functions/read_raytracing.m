% --------- DeepMIMO: A Generic Dataset for mmWave and massive MIMO ------%
% Author: Ahmed Alkhateeb
% Date: Sept. 5, 2018
% Goal: Encouraging research on ML/DL for mmWave MIMO applications and
% providing a benchmarking tool for the developed algorithms
% ---------------------------------------------------------------------- %
function [channel_params]=read_raytracing(filename_DoD,filename_DoA,filename_CIR,filename_Loc,num_paths,user_first,user_last)

DoD_array=importdata(filename_DoD);
DoA_array=importdata(filename_DoA);
CIR_array=importdata(filename_CIR);
Loc_array=importdata(filename_Loc);

total_num_users=double(DoD_array(1));
pointer=0;

DoD_array(1)=[];
DoA_array(1)=[];
CIR_array(1)=[];

channel_params_all=struct('DoD_phi',[],'DoD_theta',[],'phase',[],'ToA',[],'power',[],'num_paths',[],'loc',[]);

for Receiver_Number=1:total_num_users
    max_paths=double(DoD_array(pointer+2));
    num_path_limited=double(min(double(num_paths),max_paths));
    if (max_paths>0)
        Relevant_data_length=max_paths*4;
        Relevant_limited_data_length=num_path_limited*4;
        
        Relevant_DoD_array=DoD_array(pointer+3:pointer+2+Relevant_data_length);
        Relevant_DoA_array=DoA_array(pointer+3:pointer+2+Relevant_data_length);
        Relevant_CIR_array=CIR_array(pointer+3:pointer+2+Relevant_data_length);
        
        channel_params_all(Receiver_Number).DoD_phi=Relevant_DoD_array(2:4:Relevant_limited_data_length);
        channel_params_all(Receiver_Number).DoD_theta=Relevant_DoD_array(3:4:Relevant_limited_data_length);
        channel_params_all(Receiver_Number).DoA_phi=Relevant_DoA_array(2:4:Relevant_limited_data_length);
        channel_params_all(Receiver_Number).DoA_theta=Relevant_DoA_array(3:4:Relevant_limited_data_length);
        channel_params_all(Receiver_Number).phase=Relevant_CIR_array(2:4:Relevant_limited_data_length);
        channel_params_all(Receiver_Number).ToA=Relevant_CIR_array(3:4:Relevant_limited_data_length);
        channel_params_all(Receiver_Number).power=1e-3*(10.^(.1*(30+Relevant_CIR_array(4:4:Relevant_limited_data_length))));
        channel_params_all(Receiver_Number).num_paths=num_path_limited;
        channel_params_all(Receiver_Number).loc=Loc_array(Receiver_Number,2:4);
    else
        channel_params_all(Receiver_Number).DoD_phi=[];
        channel_params_all(Receiver_Number).DoD_theta=[];
        channel_params_all(Receiver_Number).DoA_phi=[];
        channel_params_all(Receiver_Number).DoA_theta=[];
        channel_params_all(Receiver_Number).phase=[];
        channel_params_all(Receiver_Number).ToA=[];
        channel_params_all(Receiver_Number).power=[];
        channel_params_all(Receiver_Number).num_paths=0;
        channel_params_all(Receiver_Number).loc=Loc_array(Receiver_Number,2:4);
    end
    pointer=double(pointer+max_paths*4+2);
end

channel_params=channel_params_all(1,double(user_first):double(user_last));

end