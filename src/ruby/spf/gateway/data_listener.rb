require 'socket'
require 'concurrent'
require 'spf/common/logger'


module SPF
  module Gateway
    class DataListener

      include SPF::Logging

      def initialize(host, port, service_manager)
        @host = host; @port = port; @service_manager = service_manager
        @udp_socket = UDPSocket.new

        # We adopt a thread pool architecture because it should use multi-core
        # CPU architectures more efficiently. Also, cached thread pools are
        # supposed to work very well with short processing tasks.
        @pool = Concurrent::CachedThreadPool.new
      end

      def run
        logger.info "*** Pig: Starting processing endpoint on #{@host}:#{@port} ***"

        @udp_socket.setsockopt(:SOCKET, :REUSEADDR, true)
        @udp_socket.setsockopt(:SOCKET, :REUSEPORT, true)
        @udp_socket.bind(@host, @port)

        loop do
          logger.info "*** Received raw_data***"
          raw_data, source = @udp_socket.recvfrom(65535)          # source is an IPSocket#{addr,peeradr} object
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
