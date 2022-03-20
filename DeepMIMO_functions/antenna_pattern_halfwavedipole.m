% --------- DeepMIMO: A Generic Dataset for mmWave and massive MIMO ------%
% Authors: Ahmed Alkhateeb, Umut Demirhan, Abdelrahman Taha 
% Date: March 17, 2022
% Goal: Encouraging research on ML/DL for MIMO applications and
% providing a benchmarking tool for the developed algorithms
% ---------------------------------------------------------------------- %

function Directivity = antenna_pattern_halfwavedipole(Theta,Phi)
    %RADIATION PATTERN EFFECT on the receive power calculation
    % Calculate Half-wave dipole directivity in a given direction
    % It is an omni directional radiation pattern 
    % that depends only on the zenith angle (theta)
    
    Directivity_max = 1.6409223769; % Half-wave dipole maximum directivity
    
    idx=find(Theta==0);                                                              
    Theta(idx)= 1e-4;               
    Directivity = Directivity_max.*((cos((pi/2).*cosd(Theta)).^2)./(sind(Theta).^2)); 
    Directivity(idx) = 0;
    
end

