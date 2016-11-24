require 'spf-common/controller'

module SPF
  class Controller < SPF::Common::Controller
    
    def initialize(host, port)
      config = PIGConfiguration::load_from_file(conf_filename)
      @pigs = config.pigs
      @pig_connections = {}
      @reconf_template = read_reconf_template(template_filename)
      
      connect_to_pigs
      
      super(host, port)
    end

    private
    
    #def run(opts = {})
      #send requests to the PIG
#      first_req = ""
#      second_req = ""
#      third_req = ""
#      
#      sleep 3
#      Thread.new { SPF::Request.new(@iot_address, @iot_port, first_req).run }
#      sleep 10
#      Thread.new { SPF::Request.new(@iot_address, @iot_port, second_req).run }
#      sleep 10
#      Thread.new { SPF::Request.new(@iot_address, @iot_port, third_req).run }
      
    #end

    
    # REQUEST participants/find
    # User 3;44.838124,11.619786;find "water"
    
      def handle_connection(user_socket)
        _, port, host = user_socket.peeraddr
        puts "*** Received connection from #{host}:#{port}"
        
        header = user_socket.gets
        body = user_socket.gets
        
        user_socket.close
        
        # get gps coords
        lat, long = extract_gps_from_request_body(body)
        
        pig = find_nearest_pig(lat, long)
        pig_socket = @pig_connections[(pig.ip + ":" + pig.port).to_sym]      # check
        if pig_socket.nil? or pig_socket.closed?
          pig_socket = TCPSocket.new(pig.ip, pig.port)
          @pig_connections[(pig.ip + ":" + pig.port).to_sym] = pig_socket
        end
        
        pig_socket.puts(header)
        pig_socket.puts(body)
        
      rescue EOFError
        puts "*** #{host}:#{port} disconnected"
        socket.close
      end

      # Open socket to all pigs in the @pigs list
      def connect_to_pigs
        
      end
      
      def read_reconf_template(template_filename)
        @reconf_template = File.new(template_filename, 'r').read
      end
      
  end
end
