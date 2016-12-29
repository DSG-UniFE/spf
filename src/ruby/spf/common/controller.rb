require 'socket'
require 'concurrent'
require 'spf/common/logger'

# disable useless DNS reverse lookup
BasicSocket.do_not_reverse_lookup = true

module SPF
  module Common
    class Controller

      include SPF::Logging

      def initialize(host, port)
        # open a TCPServer as programming endpoint
        logger.info "*** Common controller: Starting programming endpoint on #{host}:#{port} ***"
        @programming_endpoint = TCPServer.new(host, port)
        @keep_going = Concurrent::AtomicBoolean.new(true)
      end

      def run(opts = {})
        if opts[:one_shot]
          # run in "one shot" mode, for testing and debugging purposes only
          handle_connection @programming_endpoint.accept
        else
          # We adopt an iterative/sequential single-thread server architecture
          # because:
          # 1. we don't really have any concurrency need;
          # 2. having multiple concurrent service threads would require us to
          #    implement a locking mechanism for the shared Configuration object
          counter = 0
          while @keep_going.true?
            logger.info "*** Common controller: calling handle_connection ***"
            handle_connection @programming_endpoint.accept
            counter += 1
          end
        end
      ensure
        @programming_endpoint.close
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
