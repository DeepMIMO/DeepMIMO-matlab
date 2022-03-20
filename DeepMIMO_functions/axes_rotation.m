function [DoD_theta_LCS, DoD_phi_LCS, DoA_theta_LCS, DoA_phi_LCS] = axes_rotation(TX_rot, DoD_theta_GCS, DoD_phi_GCS, RX_rot, DoA_theta_GCS, DoA_phi_GCS)
    %AXES ROTATION EFFECT on the DoDs and the DOAs

    % Arbitrary 3D axes rotation from the "global coordinate system" (x,y,z) of the
    % chose scenario to the "the local coordinate systems" (x',y',z') relative
    % to the new panel orientation

    [DoD_theta_LCS,DoD_phi_LCS]= angle_transformation(TX_rot,DoD_theta_GCS,DoD_phi_GCS);
    [DoA_theta_LCS,DoA_phi_LCS]= angle_transformation(RX_rot,DoA_theta_GCS,DoA_phi_GCS);
end


function [Theta2, Phi2] = angle_transformation(Rot, Theta, Phi)

    % Phi = wrapTo360(Phi);
    Alpha = Rot(3);
    Beta = Rot(2);
    Gamma = Rot(1);
    %3GPP TR 38.901 definitions: 
    % Alpha is the angle of rotation around the z-axis (sometimes named the bearing angle) 
    % Beta is the angle of rotation around the y-axis (sometimes named the downtilt angle) 
    % Gamma is the angle of rotation around the x-axis (sometimes named the slant angle) 

    %New Theta value (Theta is the zenith angle)
    Theta2=acosd( (cosd(Beta).*cosd(Gamma).*cosd(Theta)) + ( sind(Theta).*( (sind(Beta).*cosd(Gamma).*cosd(Phi-Alpha)) - (sind(Gamma).*sind(Phi-Alpha)) ) ));

    %New Phi value (Phi is the azimuth angle)
    Phi2_real = (cosd(Beta).*sind(Theta).*cosd(Phi-Alpha)) - (sind(Beta).*cosd(Theta));
    Phi2_imag = (cosd(Beta).*sind(Gamma).*cosd(Theta)) + (sind(Theta).*( (sind(Beta).*sind(Gamma).*cosd(Phi-Alpha)) + (cosd(Gamma).*sind(Phi-Alpha)) ))  ;
    Phi2 = wrapTo360(angle(complex(Phi2_real,Phi2_imag)).*(180/pi));
end
