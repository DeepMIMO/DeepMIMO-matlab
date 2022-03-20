classdef progress_counter < handle
    properties
        counter = 0
        print_accuracy = 0.001
        print_divisor = 0
        max_value = 0
        reverseStr = 0
    end
    
    methods
        % Constructor
        function this = progress_counter(max_value)
            this.max_value = max_value;
            this.print_divisor = max(1, floor(this.print_accuracy*max_value));
            this.print_progress();
        end
        
        function increment(this)
            this.counter = this.counter + 1;
            if rem(this.counter, this.print_divisor) == 0 || this.counter==this.max_value
                this.print_progress();
            end
        end
        
        function reset(this)
            this.counter = 0;
        end
        
        function print_progress(this)
            percentDone = 100 * this.counter / this.max_value;
            msg = sprintf('- Percentage completed: %3.1f', percentDone);
            fprintf([this.reverseStr, msg]);
            this.reverseStr = repmat(sprintf('\b'), 1, length(msg));
        end
    end
end