function filter = pulse_raised_cosine(t, rolloff)
    out_ind = logical((t == (1/(rolloff*2))) + (t == (-1/(rolloff*2))));
    t(out_ind) = 0;
    filter = pulse_sinc(t).*cos(pi*rolloff*t)./(1-(2*rolloff*t).^2);
    filter(out_ind) = (pi/4)*pulse_sinc(1/(rolloff*2));
end