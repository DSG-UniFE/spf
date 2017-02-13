require 'socket'
require 'concurrent'

require 'spf/common/logger'
require 'spf/gateway/sensor_receiver'
require 'spf/common/tcpserver_strategy'
require 'spf/common/extensions/thread_reporter'


# disable useless DNS reverse lookup
BasicSocket.do_not_reverse_lookup = true

module SPF
  module Gateway
    class DataListener

      include SPF::Logging

      DEFAULT_HOST = '0.0.0.0'
      DEFAULT_PORT = 2160

      def initialize(service_manager, benchmark, host=DEFAULT_HOST, port=DEFAULT_PORT)
        @programming_endpoint = TCPServer.new(host, port)   #TCPServer listening on host:port
        @keep_going = Concurrent::AtomicBoolean.new(true)
        @service_manager = service_manager
        @pool = Concurrent::CachedThreadPool.new
        @threads = Array.new
        @benchmark = benchmark
      end

      def run(opts = {})
        if opts[:one_shot]
          # run in "one shot" mode, for testing and debugging purposes only
          logger.info "*** #{self.class.name}: ONE-SHOT - calling handle_connection ***"
          handle_connection @programming_endpoint.accept
        else
          counter = 0
          while @keep_going.true?
            logger.info "*** #{self.class.name}: calling handle_connection ***"
            handle_connection @programming_endpoint.accept
            counter += 1
          end
          # @threads.each { |thread| thread.join }
          # @threads.map(&:join)
        end
      ensure
        @threads.each { |thread| thread.join } if @threads

        @programming_endpoint.close
      end

      private

        def shutdown
          @keep_going.make_false
        end

        def handle_connection(socket)
          _, port, host = socket.peeraddr
          logger.info "*** #{self.class.name}: Received connection from sensor #{host}:#{port} ***"
          @threads << Thread.new { SPF::Gateway::SensorReceiver.new(socket, @pool, @service_manager, @benchmark).run }
        rescue => e
          logger.error "*** #{self.class.name}: #{e.message} ***"
        end

    end
  end
end
