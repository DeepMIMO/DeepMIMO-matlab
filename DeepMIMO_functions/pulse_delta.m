function Local_delta_output = pulse_delta(Time_vector)
% Local sinc function definition

Local_delta_output = zeros(size(Time_vector));
Local_delta_output(Time_vector==0)= 1;

end
