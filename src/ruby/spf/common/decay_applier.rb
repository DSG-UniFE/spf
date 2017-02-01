module SPF
  module Common
    module DecayApplier
      
      def self.apply_decay(value, rules)
          # enforce maximum value if needed
          raise SPF::Common:OutOfRangeException, "#{self.class.name}: Parameter out of range : #{value}" unless value >= 0
          return 0.0 if value > rules[:max]

          # apply decay according to the requested type
          decay_modifier = case rules[:type]
          when :exponential
            Math.exp( value / (Math::E * (value - rules[:max])))
          when :linear
            1.0 - ( value / rules[:max].to_f )
          else
            1.0 # default is no decay at all
          end 

        end

    end
  end
end
