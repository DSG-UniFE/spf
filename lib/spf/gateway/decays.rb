module SPF
  module Gateway
    class Decays
      def self.exponential_decay(initial_value, elapsed_time, exponential_decay_constant)
        initial_value * Math.exp(-exponential_decay_constant * elapsed_time)
      end
      
      def self.linear_decay(initial_value, elapsed_time, linear_decay_constant)
        result = initial_value - (elapsed_time * linear_decay_constant)
        return result if result > 0
        0
      end
    end
  end
end
