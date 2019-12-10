module SPF
  module Gateway
    class Broker

      attr_reader :address, :port, :topics

       def initialize(address, port, topics)
        puts "sa"
         @address = address
         @port = port
         @topics = topics
       end

    end

    class BrokerFactory
      def self.create(address:, port:, topics:)
        Broker.new(address, port, topics)
      end
    end
  end
end


