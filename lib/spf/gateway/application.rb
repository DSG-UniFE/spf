require 'java'

module SPF
  module Gateway
    class Application

      attr_reader :priority

      def initialize(priority, time_decay_manner, distance_decay_manner, time_decay_constant, distance_decay_constant)
        @priority = priority
        @time_decay_constant = time_decay_constant
        @distance_decay_constant = distance_decay_constant

        case time_decay_manner
        when /exponential/
          @time_decay_type = :exponential
        when /linear/
          @time_decay_type = :linear
        else
          raise 'Time decay type #{time_decay_manner} not recognized!'
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
        if @time_decay_type == :exponential
          exponential_decay(initial_value, elapsed_time, @time_decay_constant)
        else # :linear
          linear_decay(initial_value, elapsed_time, @time_decay_constant)
        end
      end

      def distance_decay(initial_value, elapsed_time)
         raise 'Method distance_decay not implemented'
      end

      def disseminate
        # TODO: implement
      end

      private

        def exponential_decay(initial_value, elapsed_time, exponential_decay_constant)
          initial_value * Math.exp(-exponential_decay_constant * elapsed_time)
        end

        def linear_decay(initial_value, elapsed_time, linear_decay_constant)
          result = initial_value - (elapsed_time * linear_decay_constant)
          return result if result > 0
          0
        end
    end
  end
end
