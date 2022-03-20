function Local_sinc_output = pulse_sinc(Time_vector)
% Local sinc function definition

i=find(Time_vector==0);                                                              
Time_vector(i)= 1;               
Local_sinc_output = sin(pi*Time_vector)./(pi*Time_vector);                                                     
Local_sinc_output(i) = 1;
end
