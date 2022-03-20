function Directivity = antenna_pattern(Theta,Phi)
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

