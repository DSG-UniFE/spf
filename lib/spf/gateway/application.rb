module SPF
  module Gateway
    class Application
      attr_reader :priority

      def initialize(priority, ...)
        @priority = priority
      end

      def time_decay
        # TODO: implement
      end

      def distance_decay
        # TODO: implement
      end

      def disseminate
        # TODO: implement
      end
    end
  end
end
