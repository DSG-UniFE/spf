require 'socket'
require 'concurrent'
require 'json'

require 'spf/common/tcpserver_strategy'
require 'spf/common/logger'
require 'spf/common/validate'

require_relative './pig_ds'


module SPF
  module Controller
    class PigManager < SPF::Common::TCPServerStrategy

    include SPF::Logging

      @@DEFAULT_HOST = "localhost"
      @@DEFAULT_PORT = 52160

      def initialize(pigs, pigs_tree, host=@@DEFAULT_HOST, port=@@DEFAULT_PORT)
        super(host, port, self.class.name)

        @pigs = pigs
        @pigs_lock = Concurrent::ReadWriteLock.new
        @pigs_tree = pigs_tree
        @pig_tree_lock = Concurrent::ReadWriteLock.new
      end

      private

        def handle_connection(socket)
          _, port, host = socket.peeraddr
          logger.info "*** #{self.class.name}: Received connection from #{host}:#{port} ***"

          header, body = receive_request(socket, host, port)
          if header.nil? or body.nil?
            logger.warn "*** #{self.class.name}: Received wrong message from #{host}:#{port} ***"
            return
          end

          pig = validate_request(header, body, host, port)
          if pig.nil?
            socket.puts "REFUSED"
            logger.warn "*** #{self.class.name}: Refused connection from #{host}:#{port} ***"
            return
          end

          socket.puts "OK!"

          pig.socket = socket
          pig.ip = host
          pig.port = port

          @pigs_lock.with_write_lock do
            if @pigs.key?(pig.alias_name)
              @pigs[pig.alias_name].socket = pig.socket
              @pigs[pig.alias_name].ip = pig.ip
              @pigs[pig.alias_name].port = pig.port
              logger.info "*** #{self.class.name}: Successfully updated registration info of PIG #{pig.alias_name} ***"
            else
              @pigs[pig.alias_name] = pig
              logger.info "*** #{self.class.name}: Successfully registered PIG #{pig.alias_name} ***"
            end
          end

          @pig_tree_lock.with_write_lock do
            @pigs_tree.add(pig)
          end
        rescue IOError
          logger.warn "*** #{self.class.name}: Closed stream to PIG #{pig.ip}:#{pig.port}! ***"
          pig.socket = nil
        rescue Errno::EHOSTUNREACH
          logger.warn "*** #{self.class.name}: PIG #{pig.ip}:#{pig.port} unreachable! ***"
          pig.socket = nil
        rescue Errno::ECONNREFUSED
          logger.warn "*** #{self.class.name}: Connection refused by PIG #{pig.ip}:#{pig.port}! ***"
          pig.socket = nil
        rescue Errno::ECONNRESET
          logger.warn "*** #{self.class.name}: Connection reset by PIG #{pig.ip}:#{pig.port}! ***"
          pig.socket = nil
        rescue Errno::ECONNABORTED
          logger.warn "*** #{self.class.name}: Connection aborted by PIG #{pig.ip}:#{pig.port}! ***"
          pig.socket = nil
        rescue EOFError
          logger.warn "*** #{self.class.name}: PIG #{pig.ip}:#{pig.port} disconnected! ***"
          pig.socket = nil
        end

        def validate_request(header, body, host, port)
          request = header.split(' ')
          bytesize = request[2].to_i
          unless request[0].eql? "REGISTER" and request[1].eql? "PIG"
            logger.warn "*** #{self.class.name}: Received wrong header from #{host}:#{port} ***"
            return
          end
          unless bytesize > 0
            logger.warn "*** #{self.class.name}: Received wrong bytesize from #{host}:#{port} ***"
            return
          end
          unless body.bytesize == (bytesize+1)
            logger.warn "*** #{self.class.name}: Error PIG bytesize from #{host}:#{port} ***"
            return
          end

          tmp_pig = JSON.parse(body)    # parsed PIGs have keys as strings, not Symbols

          unless SPF::Common::Validate.latitude?(tmp_pig['gps_lat']) && SPF::Common::Validate.longitude?(tmp_pig['gps_lon'])
            logger.warn "*** #{self.class.name}: Error PIG GPS coordinates from #{host}:#{port} ***"
            return
          end

          PigDS.new(tmp_pig["alias_name"], 0, 0, nil, tmp_pig["gps_lat"], tmp_pig["gps_lon"])
        end

        def receive_request(socket, host, port)
          header = nil
          body = nil
          begin
            header = socket.gets
            body = socket.gets
          rescue => e
            logger.warn  "*** #{self.class.name}: Receive request error #{e.message} from #{host}:#{port} ***"
          end
          [header, body]
        end

    end
  end
end
