require 'socket'
require 'concurrent'

require 'spf/common/logger'


# disable useless DNS reverse lookup
BasicSocket.do_not_reverse_lookup = true

module SPF
  module Common
    class TCPServerStrategy

    include SPF::Logging

      def initialize(host, port, parent_class_name)
        @programming_endpoint = TCPServer.new(host, port)   #TCPServer listening on host:port
        @keep_going = Concurrent::AtomicBoolean.new(true)
        @parent_class_name = parent_class_name 
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
            logger.info "*** #{TCPServerStrategy.name} < #{@parent_class_name}: calling handle_connection ***"
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
          raise "*** #{TCPServerStrategy.name} < #{@parent_class_name}: Parent class needs to implement the handle_connection method! ***"
        end
    end
  end
end
