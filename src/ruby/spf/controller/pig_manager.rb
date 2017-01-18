require 'socket'
require 'concurrent'
require 'yaml'

require 'spf/common/tcpserver_strategy'
require 'spf/common/logger'
require 'spf/common/validate'


module SPF
  module Controller
    class PigManager < SPF::Common::TCPServerStrategy

      include SPF::Logging

      def initialize(host, port, pig_sockets, pigs_tree)
        logger.info "*** ***"
        puts "Sono in PigManager #{host}:#{port}"

        super(host, port)
        puts "Dopo super"

        @pig_sockets = pig_sockets
        @pig_sockets_lock = Concurrent::ReadWriteLock.new
        @pigs_tree = pigs_tree
        @pig_tree_lock = Concurrent::ReadWriteLock.new

      end

      def handle_connection(socket)
        # logger.info "*** PigManager: Waiting connection on #{@host}:#{@port} ***"
        # socket = @programming_endpoint.accept
        _, port, host = socket.peeraddr
        logger.info "*** PigManager: Received connection from #{host}:#{port} ***"

        header, body = receive_request(port, host, user_socket)
        if header.nil? or body.nil?
          logger.warn "*** PigManager: Received wrong message from #{host}:#{port} ***"
          next
        end

        unless pig.nil?
          socket.puts "REFUSED"
          next
        end

        socket.puts "OK!"

        pig[:ip] = host
        pig[:port] = port
        pig[:applications] = {}

        @pig_sockets_lock.with_write_lock do
          @pig_sockets["#{host}:#{port}".to_sym] = socket
        end

        @pig_tree_lock.with_write_lock do
          @pigs_tree.insert([pig['gps_lat'], pig['gps_lon']], pig)
        end

      end

      def validate_request(header, body)
        pig = nil
        request = parse_request_header(header)
        bytesize = request[3].to_i
        unless request[0].eql? "REGISTER" and request[1].eql? "PIG"
          logger.warn "*** PigManager: Received wrong header from #{host}:#{port} ***"
          return
        end
        unless bytesize > 0
          logger.warn "*** PigManager: Received wrong bytesize from #{host}:#{port} ***"
          return
        end
        pig = YAML.load(body)
        unless pig.bytesize == bytesize
          logger.warn "*** PigManager: Error PIG bytesize from #{host}:#{port} ***"
          return
        end
        unless SPF::Common::Validate.latitude?(pig['gps_lat']) && SPF::Common::Validate.longitude?(pig['gps_lon'])
          logger.warn "*** PigManager: Error PIG GPS coordinates from #{host}:#{port} ***"
          return
        end
        pig
      end

      def receive_request(port, host, socket)
          header = nil
          body = nil
          begin
            header = socket.gets
            body = socket.gets
          rescue => e
            logger.warn  "*** PigManager: Receive request error #{e.message} from #{host}:#{port} ***"
          end
          [header, body]
        end

      # REGISTER PIG #{registration.bytesize}
      def parse_request_header(header)
        header.split(' ')
      end


      private

        def shutdown
          @keep_going.make_false
        end

    end
  end
end
