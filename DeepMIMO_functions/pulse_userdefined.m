function Local_sinc_output = pulse_userdefined(Time_vector)
%A user-defined pulse shaping and matched filtering functions
% The current function below is for sinc pulse shaping and matched filter

i=find(Time_vector==0);                                                              
Time_vector(i)= 1;               
Local_sinc_output = sin(pi*Time_vector)./(pi*Time_vector);                                                     
Local_sinc_output(i) = 1;
end
