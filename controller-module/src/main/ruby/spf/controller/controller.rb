require 'spf/common/controller'

module SPF
  class Controller < SPF::Common::Controller
    DEFAULT_PIG_PORT = 52160
    
    def initialize(host, port, pig_address, pig_port = DEFAULT_PIG_PORT)
      @pig_address = pig_address
      @pig_port = pig_port
      super(host, port)
    end

    private
    
    def run(opts = {})
      #send requests to the PIG
      first_req = ""
      second_req = ""
      third_req = ""
      
      sleep 3
      Thread.new { SPF::Request.new(@iot_address, @iot_port, first_req).run }
      sleep 10
      Thread.new { SPF::Request.new(@iot_address, @iot_port, second_req).run }
      sleep 10
      Thread.new { SPF::Request.new(@iot_address, @iot_port, third_req).run }
      
    end

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
