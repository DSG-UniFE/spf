require 'java'

module SPF
  module Gateway
    class Application

      attr_reader :priority

      def initialize(priority, time_decay_type, distance_decay_type, time_decay_constant, distance_decay_constant)
        @priority = priority
        @time_decay_constant = time_decay_constant
        @distance_decay_constant = distance_decay_constant

        case time_decay_type
        when /exponential/
          @time_decay_type = :exponential
        when /linear/
          @time_decay_type = :linear
        else
          raise 'Time decay type #{time_decay_type} not recognized!'
        end

        case distance_decay_type
        when /exponential/
          @distance_decay_type = :exponential
        when /linear/
          @distance_decay_type = :linear
        else
          raise 'Distance decay type #{distance_decay_type} not recognized'
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
        if @distance_decay_type == :exponential
          exponential_decay(initial_value, elapsed_time, @time_decay_constant)
        else # :linear
          linear_decay(initial_value, elapsed_time, @distance_decay_constant)
        end
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
