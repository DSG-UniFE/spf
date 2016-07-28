require 'socket'
require 'concurrent'

module SPF
  module Gateway
    class Processor
      def initialize(host, port, conf)
        @host = host; @port = port; @conf = conf

        # We adopt a thread pool architecture because it should use multi-core
        # CPU architectures more efficiently. Also, cached thread pools are
        # supposed to work very well with short processing tasks.
        @pool = Concurrent::CachedThreadPool.new
      end

      def run
        puts "*** Starting processing endpoint on #{@host}:#{@port} ***"

        Socket.udp_server_loop(@port) do |raw_data, source|
          # source is a UDPSource object
          @conf.with_services_interested_in(raw_data) do |svc|
            @pool.post do
              svc.new_data(raw_data)
            end
          end
        end
      end
      
    end
  end
end
