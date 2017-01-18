require 'socket'
require 'concurrent'

require 'spf/common/logger'


module SPF
  module Controller
    class PigManager

      include SPF::Logging

      def initialize(host, port, sockets)
        @host = host
        @port = port
        @sockets = sockets
        @sockets_lock = Concurrent::ReadWriteLock.new
        # open a TCPServer as programming endpoint
        logger.info "*** PigManager: Starting programming endpoint on #{host}:#{port} ***"
        @programming_endpoint = TCPServer.new(@host, @port)
        logger.info "*** PigManager: Started programming endpoint on #{host}:#{port} ***"
        @keep_going = Concurrent::AtomicBoolean.new(true)
      end

      def run
        while @keep_going.true?
          logger.info "*** PigManager: Waiting connection on #{@host}:#{@port} ***"
          socket = @programming_endpoint.accept
          _, port, host = socket.peeraddr
          logger.info "*** PigManager: Received connection from #{host}:#{port} ***"

          @sockets_lock.with_write_lock do
            @sockets["#{host}:#{port}".to_sym] << socket
          end

        end
      end

      private

        def shutdown
          @keep_going.make_false
        end

    end
  end
end
