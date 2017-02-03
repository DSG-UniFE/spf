require 'spf/common/exceptions'

module SPF
  module Common
    module DecayApplier
      
      def apply_decay(value, rules)
        # enforce maximum value if needed
        raise OutOfRangeException, "#{self.class.name}: Parameter out of range: #{value}" unless value >= 0
        return 0.0 if value >= rules[:max]
        
        begin
          # apply decay according to the requested type
          self.send(rules[:type], value, rules[:max].to_f)
        rescue NoMethodError => e
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
