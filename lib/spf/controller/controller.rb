require 'spf/common/controller'

module SPF
  class Controller < SPF::Common::Controller
    def initialize(host, port)
      super(host, port)
    end

    private

      def handle_connection(socket)
        _, port, host = socket.peeraddr
        puts "*** Received connection from #{host}:#{port}"
        loop { socket.write socket.readpartial(4096) }
      rescue EOFError
        puts "*** #{host}:#{port} disconnected"
        socket.close
      end
  end
end
