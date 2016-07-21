require 'java'

module SPF
  module Gateway
    class Application
      
      attr_reader :priority

      def initialize(priority, time_decay_manner, distance_decay_manner, time_decay_constant, distance_decay_constant)
        @priority = priority
        @time_decay_constant = time_decay_constant
        @distance_decay_constant = distance_decay_constant
        
        if time_decay_manner == "exponential"
          define_method("time_decay") do |initial_value, elapsed_time|
            Decays.exponential_decay(initial_value, elapsed_time, @time_decay_constant)
          end
        elsif time_decay_manner == "linear"
          define_method("time_decay") do |initial_value, elapsed_time, decay_constant|
            Decays.linear_decay(initial_value, elapsed_time, @time_decay_constant)
          end
        else
          raise 'Time decay #{time_decay_manner} manner not recognized'
        end
        if distance_decay_manner == "exponential"
          define_method("distance_decay") do |initial_value, elapsed_time|
            Decays.exponential_decay(initial_value, elapsed_time, @distance_decay_constant)
          end
        elsif distance_decay_manner == "linear"
          define_method("distance_decay") do |initial_value, elapsed_time|
            Decays.linear_decay(initial_value, elapsed_time, @distance_decay_constant)
          end
        else
          raise 'Distance decay #{distance_decay_manner} manner not recognized'
        end
      end
      
      def time_decay(initial_value, elapsed_time)
         raise 'Method time_decay not implemented'
      end
      
      def distance_decay(initial_value, elapsed_time)
         raise 'Method distance_decay not implemented'
      end

      def disseminate
        # TODO: implement
      end
    end
  end
end
