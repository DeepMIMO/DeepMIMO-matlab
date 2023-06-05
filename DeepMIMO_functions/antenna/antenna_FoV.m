% --------- DeepMIMO: A Generic Dataset for mmWave and massive MIMO ------%
% Authors: Ahmed Alkhateeb, Umut Demirhan, Abdelrahman Taha 
% Date: March 17, 2022
% Goal: Encouraging research on ML/DL for MIMO applications and
% providing a benchmarking tool for the developed algorithms
% ---------------------------------------------------------------------- %

function path_inclusion = antenna_FoV(theta, phi, FoV_limits)
    path_inclusion = ((phi <= 0+FoV_limits(1)/2) ...
                       | (phi >= 360-FoV_limits(1)/2)) ...
                       & ((theta <= 90+FoV_limits(2)/2) ...
                       & (theta >= 90-FoV_limits(2)/2));
end

