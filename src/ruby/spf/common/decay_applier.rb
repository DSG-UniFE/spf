require 'spf/common/exceptions'
require 'spf/common/logger'


module SPF
  module Common
    module DecayApplier
      
      include SPF::Logging

      # Calculate the VoI from the parameters.
      #
      # @param io_quality [Float] The quality of the IO.
      # @param app_priority [Float] The priority of the application.
      # @param norm_reqs [Float] The number of requestors interested in the IO, normalized by  
      #                          the highest number of requests received by all services.
      # @param rds_time [Float] The time decay factor.
      # @param prox_d [Float] The distance decay factor.
      def apply_decay(value, rules)
        raise OutOfRangeException, "#{self.class.name}: Parameter out of range: #{value}" unless value >= 0
        return 0.0 if value >= rules[:max]
        
        begin
          # apply decay according to the requested type
          self.send(rules[:type], value, rules[:max].to_f)
        rescue NoMethodError => e
          logger.warn "*** #{self.class.name}: The specified decay type '#{rules[:type]}' is not valid ***"
          1.0
        end
      end
      
      def exponential(value, max)
        Math.exp(value / (Math::E * (value - max)))
      end
      
      def linear(value, max)
        1.0 - (value / max)
      end

    end
  end
end
