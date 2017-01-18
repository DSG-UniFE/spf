require 'socket'
require 'concurrent'

require 'spf/common/logger'
require 'spf/common/extensions/fixnum'


# disable useless DNS reverse lookup
BasicSocket.do_not_reverse_lookup = true

module SPF
  module Common
    class LoopConnector

      include SPF::Logging
      
      RECONNECTION_TIMEOUT = 3.seconds

      def initialize(remote_host, remote_port, reconnection_timeout = RECONNECTION_TIMEOUT)
        # open a TCPServer as programming endpoint
        logger.info "*** Common::LoopConnector: started LoopConnector to address #{host}:#{port} ***"
        @host = remote_host
        @port = remote_port
        @keep_going = Concurrent::AtomicBoolean.new(true)
        @reconnection_timeout = reconnection_timeout
      end

      def run(opts = {})
        if opts[:one_shot]
          # run in "one shot" mode, for testing and debugging purposes only
          begin
            logger.info "*** Common::LoopConnector: connection attempt to #{@host}:#{@port} ***"
            handle_connection Socket.tcp(@host, @port)
          rescue SocketError => e
            logger.warn "*** Common::LoopConnector: connection attempt failed ***"
          rescue => e
            logger.error "*** Common::LoopConnector: connection attempt failed with an unexpected error ***"
            logger.error e.class.inspect
          end
          
          return
        end
        
        counter = 1
        while @keep_going.true?
          begin
            logger.info "*** Common::LoopConnector: connection attempt ##{counter} to #{@host}:#{@port} ***"
            socket = Socket.tcp(@host, @port)
            handle_connection socket
          rescue SocketError => e
            logger.warn "*** Common::LoopConnector: connection attempt failed - waiting #{@reconnection_timeout}s before retrying ***"
            sleep(@reconnection_timeout)
          rescue => e
            logger.error "*** Common::LoopConnector: connection attempt failed with an unexpected error - waiting #{@reconnection_timeout}s before retrying ***"
            logger.error e.class.inspect
            sleep(@reconnection_timeout)
          end
        end
      end

      
      private

        def shutdown
          @keep_going.make_false
        end

        def handle_connection(socket)
          raise "*** Common controller: You need to implement the handle_connection method! ***"
        end
        
    end
  end
end
