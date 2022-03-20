% --------- DeepMIMO: A Generic Dataset for mmWave and massive MIMO ------%
% Author: Ahmed Alkhateeb
% Date: Sept. 5, 2018 
% Goal: Encouraging research on ML/DL for mmWave MIMO applications and
% providing a benchmarking tool for the developed algorithms
% ---------------------------------------------------------------------- %
function [DeepMIMO_dataset,params]=DeepMIMO_generator(params)

% -------------------------- DeepMIMO Dataset Generation -----------------%
fprintf(' DeepMIMO Dataset Generation started \n')

% Read scenario parameters
file_scenario_params=strcat('./RayTracing Scenarios/',params.scenario,'/',params.scenario,'.params.mat');
load(file_scenario_params)

params.num_BS=num_BS;

num_rows=max(min(user_grids(:,2),params.active_user_last)-max(user_grids(:,1),params.active_user_first)+1,0);
params.num_user=sum(num_rows.*user_grids(:,3));                     % total number of users
 
current_grid=min(find(max(params.active_user_first,user_grids(:,2))==user_grids(:,2)));
user_first=sum((max(min(params.active_user_first,user_grids(:,2))-user_grids(:,1)+1,0)).*user_grids(:,3))-user_grids(current_grid,3)+1;
user_last=user_first+params.num_user-1;
 
BW=params.bandwidth*1e9;                                     % Bandwidth in Hz
 
% Reading ray tracing data
fprintf(' Reading the channel parameters of the ray-tracing scenario %s', params.scenario)
count_done=0;
reverseStr=0;
percentDone = 100 * count_done / length(params.active_BS);
msg = sprintf('- Percent done: %3.1f', percentDone); %Don't forget this semicolon
fprintf([reverseStr, msg]);
reverseStr = repmat(sprintf('\b'), 1, length(msg));
    
for t=1:1:params.num_BS
    if sum(t == params.active_BS) ==1
        filename_DoD=strcat('./RayTracing Scenarios/',params.scenario,'/',params.scenario,'.',int2str(t),'.DoD.mat');
        filename_DoA=strcat('./RayTracing Scenarios/',params.scenario,'/',params.scenario,'.',int2str(t),'.DoA.mat');
        filename_CIR=strcat('./RayTracing Scenarios/',params.scenario,'/',params.scenario,'.',int2str(t),'.CIR.mat');
        filename_Loc=strcat('./RayTracing Scenarios/',params.scenario,'/',params.scenario,'.Loc.mat');
        [TX{t}.channel_params]=read_raytracing(filename_DoD,filename_DoA,filename_CIR,filename_Loc,params.num_paths,user_first,user_last); 
 
        count_done=count_done+1;
        percentDone = 100 * count_done / length(params.active_BS);
        msg = sprintf('- Percent done: %3.1f', percentDone); %Don't forget this semicolon
        fprintf([reverseStr, msg]);
        reverseStr = repmat(sprintf('\b'), 1, length(msg));
    end
end


% Constructing the channel matrices 
TX_count=0;
for t=1:1:params.num_BS
    if sum(t == params.active_BS) ==1
        fprintf('\n Constructing the DeepMIMO Dataset for BS %d', t)
        reverseStr=0;
        percentDone = 0;
        msg = sprintf('- Percent done: %3.1f', percentDone); %Don't forget this semicolon
        fprintf([reverseStr, msg]);
        reverseStr = repmat(sprintf('\b'), 1, length(msg));
        TX_count=TX_count+1;
        for user=1:1:params.num_user         
          [DeepMIMO_dataset{TX_count}.user{user}.channel]=construct_DeepMIMO_channel(TX{t}.channel_params(user),params.num_ant_x,params.num_ant_y,params.num_ant_z, ...
              BW,params.num_OFDM,params.OFDM_sampling_factor,params.OFDM_limit,params.ant_spacing);
          DeepMIMO_dataset{TX_count}.user{user}.loc=TX{t}.channel_params(user).loc;
          
          percentDone = 100* round(user / params.num_user,2);
          msg = sprintf('- Percent done: %3.1f', round(percentDone,2)); %Don't forget this semicolon
          fprintf([reverseStr, msg]);
          reverseStr = repmat(sprintf('\b'), 1, length(msg));
        end       
    end   
end

if params.saveDataset==1
    sfile_DeepMIMO=strcat('./DeepMIMO Dataset/DeepMIMO_dataset.mat');
    save(sfile_DeepMIMO,'DeepMIMO_dataset','-v7.3');
end

fprintf('\n DeepMIMO Dataset Generation completed \n')