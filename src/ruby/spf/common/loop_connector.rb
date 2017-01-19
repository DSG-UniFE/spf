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

      def initialize(remote_host, remote_port, parent_class_name, reconnection_timeout=RECONNECTION_TIMEOUT)
        # open a TCPServer as programming endpoint
        @host = remote_host
        @port = remote_port
        @parent_class_name = parent_class_name
        @keep_going = Concurrent::AtomicBoolean.new(true)
        @reconnection_timeout = reconnection_timeout
      end

      def run(opts = {})
        if opts[:one_shot]
          # run in "one shot" mode, for testing and debugging purposes only
          begin
            logger.info "*** #{LoopConnector.class.name} < #{@parent_class_name}: connection attempt to #{@host}:#{@port} ***"
            handle_connection Socket.tcp(@host, @port)
          rescue SocketError => e
            logger.warn "*** #{LoopConnector.class.name} < #{@parent_class_name}: connection attempt failed ***"
          rescue => e
            logger.error "*** #{LoopConnector.class.name} < #{@parent_class_name}: connection attempt failed with an unexpected error ***"
            logger.error e.class.inspect
          end

          return
        end

        counter = 1
        while @keep_going.true?
          begin
            logger.info "*** #{LoopConnector.class.name} < #{@parent_class_name}: connection attempt ##{counter} to #{@host}:#{@port} ***"
            socket = Socket.tcp(@host, @port)
            handle_connection(socket, @host, @port)
            counter = 0
          rescue SocketError => e
            logger.warn "*** #{LoopConnector.class.name} < #{@parent_class_name}: connection attempt failed - waiting #{@reconnection_timeout}s before retrying ***"
          rescue => e
            logger.error "*** #{LoopConnector.class.name} < #{@parent_class_name}: connection attempt failed with an unexpected error - waiting #{@reconnection_timeout}s before retrying ***"
            logger.error e.class.inspect
            logger.error e.backtrace
          ensure
            sleep(@reconnection_timeout)
            counter += 1
          end
        end
      end


      private

        def shutdown
          @keep_going.make_false
        end

        def handle_connection(socket, host, port)
          raise "*** #{LoopConnector.class.name} < #{@parent_class_name}: parent class needs to implement the handle_connection method! ***"
        end

    end
  end
end
