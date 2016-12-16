require 'socket'
require 'concurrent'

module SPF
  module Gateway
    class DataListener

      def initialize(host, port, service_manager)
        @host = host; @port = port; @service_manager = service_manager

        # We adopt a thread pool architecture because it should use multi-core
        # CPU architectures more efficiently. Also, cached thread pools are
        # supposed to work very well with short processing tasks.
        @pool = Concurrent::CachedThreadPool.new
      end

      def run
        puts "*** Starting processing endpoint on #{@host}:#{@port} ***"

        Socket.udp_server_loop(@port) do |raw_data, source|
          # source is a UDPSource object
          @service_manager.with_pipelines_interested_in(raw_data) do |pl|
            @pool.post do
              pl.process(raw_data, source)
            end
          end
        end
      end

    end
  end
end
