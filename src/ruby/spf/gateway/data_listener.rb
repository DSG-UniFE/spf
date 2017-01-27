require 'socket'
require 'concurrent'

require 'spf/common/logger'


module SPF
  module Gateway
    class DataListener

      include SPF::Logging

      def initialize(host, port, service_manager, request_hash)
        @request_hash = request_hash
        @host = host; @port = port; @service_manager = service_manager
        @udp_socket = UDPSocket.new

        # We adopt a thread pool architecture because it should use multi-core
        # CPU architectures more efficiently. Also, cached thread pools are
        # supposed to work very well with short processing tasks.
        @pool = Concurrent::CachedThreadPool.new
      end

      def run
        logger.info "*** #{self.class.name}: Starting processing endpoint on #{@host}:#{@port} ***"

        @udp_socket.setsockopt(:SOCKET, :REUSEADDR, true)
        @udp_socket.setsockopt(:SOCKET, :REUSEPORT, true)
        attempts = 10
        begin
          logger.info "*** #{self.class.name}: Try to bind on #{@host}:#{@port} ***"
          @udp_socket.bind(@host, @port)
          logger.info "*** #{self.class.name}: UDP Socket bind succeeded ***"
        rescue
          attempts -= 1
          attempts > 0 ? retry : fail
        end

        loop do
          raw_data, source = @udp_socket.recvfrom(65535)          # source is an IPSocket#{addr,peeradr} object
          logger.info "*** #{self.class.name}: Received raw data from UDP Socket ***"
          
          @service_manager.with_pipelines_interested_in(raw_data) do |pl|
            @request_hash.delete(pl.get_pipeline_id) if pl.request_satisfied?
            @pool.post do
              begin
              pl.process(raw_data, source)
              rescue => e
                puts e.message
                puts e.backtrace
                raise e
              end
            end
          end
          
        end
      end

    end
  end
end
