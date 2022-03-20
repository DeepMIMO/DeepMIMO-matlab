% --------- DeepMIMO: A Generic Dataset for mmWave and massive MIMO ------%
% Authors: Ahmed Alkhateeb, Umut Demirhan, Abdelrahman Taha 
% Date: March 17, 2022
% Goal: Encouraging research on ML/DL for MIMO applications and
% providing a benchmarking tool for the developed algorithms
% ---------------------------------------------------------------------- %

classdef duration_check < handle
    properties
        FFT_duration = 0
        max_ToA = 0
        violation_count = 0
        power_ratio = 0
    end
    
    methods
        % Constructor
        function this = duration_check(FFT_duration)
            this.FFT_duration = FFT_duration;
        end
        
        function add_ToA(this, power, ToA)
            max_ToA_ch = max(ToA);
            if max_ToA_ch > this.FFT_duration
                this.violation_count = this.violation_count + 1;
                pr = sum(power(ToA >= this.FFT_duration))/sum(power);
                this.power_ratio = this.power_ratio + pr;
            end
            
            if max_ToA_ch > this.max_ToA
                this.max_ToA = max_ToA_ch;
            end
        end
        
        function reset(this)
            this.max_ToA = 0;
            this.violation_count = 0;
            this.power_ratio = 0;
        end
        
        function print_warnings(this, channel_type, BS_ID)
            avg_power_ratio_FFT = this.power_ratio*100/this.violation_count;
            if this.max_ToA > this.FFT_duration && avg_power_ratio_FFT>1
                fprintf('\n Warning for BS%i %s channels: ToA of some paths of %i channels with an average total power of %.2f%% exceed the useful OFDM symbol duration and are clipped.', BS_ID, channel_type, this.violation_count, avg_power_ratio_FFT)
            end
        end
    end
end