require 'socket'
require 'timeout'
require 'concurrent'

require 'spf/common/logger'
require 'spf/common/validate'
require 'spf/common/exceptions'
require 'spf/common/extensions/fixnum'


module SPF
  module Gateway
    class SensorReceiver

      include SPF::Logging

      def initialize(socket, pool, service_manager)
        @@DEFAULT_TIMEOUT = 10.seconds
        @pool = pool
        @service_manager = service_manager
        @socket = socket
      end

      def run
        _, port, host = @socket.peeraddr
        loop do
          begin
            raw_data = receive_request(@socket, host, port)

            if raw_data.nil?
              @socket.puts "ERROR"
            else
              @socket.puts "OK!"
              next
            end

            logger.info "*** #{self.class.name}: Received raw_data from sensor #{host}:#{port} ***"

            puts "After raw_data"


            @service_manager.with_pipelines_interested_in(raw_data) do |pl|
              @pool.post do
                begin
                  puts "Inside pool"
                  pl.process(raw_data, source)
                  puts "After process"
                rescue => e
                  puts e.message
                  puts e.backtrace
                  raise e
                end
              end
            end

          rescue SPF::Common::Exceptions::WrongHeaderFormatException
            logger.warn "*** #{self.class.name}: Received header with wrong format from #{host}:#{port}! ***"
            # @socket.puts "ERROR"
          rescue SPF::Common::Exceptions::WrongRawDataReadingException
            logger.warn "*** #{self.class.name}: Received byte_size different from raw_data.size: #{byte_to_read} | #{raw_data.size}***"
            # @socket.puts "ERROR"
          rescue Timeout::Error
            logger.warn "*** #{self.class.name}: Timeout send data to sensor #{host}:#{port}! ***"
            break
          rescue IOError
            logger.warn "*** #{self.class.name}: Closed stream to sensor #{host}:#{port}! ***"
            break
          rescue Errno::EHOSTUNREACH
            logger.warn "*** #{self.class.name}: sensor #{host}:#{port} unreachable! ***"
            break
          rescue Errno::ECONNREFUSED
            logger.warn "*** #{self.class.name}: Connection refused by sensor #{host}:#{port}! ***"
            break
          rescue Errno::ECONNRESET
            logger.warn "*** #{self.class.name}: Connection reset by sensor #{host}:#{port}! ***"
            break
          rescue Errno::ECONNABORTED
            logger.warn "*** #{self.class.name}: Connection aborted by sensor #{host}:#{port}! ***"
            break
          rescue Errno::ETIMEDOUT
            logger.warn "*** #{self.class.name}: Connection to sensor #{host}:#{port} closed for timeout! ***"
            break
          rescue EOFError
            logger.warn "*** #{self.class.name}: sensor #{host}:#{port} disconnected! ***"
            break
          rescue => e
            logger.error "*** #{self.class.name}: #{e.message} ***"
            break
          end
        end
      end

      # IMAGE bytesize
      # byte
      def receive_request(socket, host, port)
        header = nil
        raw_data = ""

        header = socket.gets
        puts "header: #{header}"
        raise SPF::Common::Exceptions::WrongHeaderFormatException if header.nil?

        request, byte_to_read = parse_request_header(header)
        raise SPF::Common::Exceptions::WrongHeaderFormatException unless request.eql? "IMAGE"

        status = Timeout::timeout(@@DEFAULT_TIMEOUT) do
          raw_data = socket.read(byte_to_read)

          if raw_data.length == 0
            logger.warn "*** #{self.class.name}: Received nil raw_data from sensor #{host}:#{port} ***"
            return nil
          end
          # File.open('image.png', 'wb') do |f|
          #   f.write(raw_data)
          # end
          # puts "Wrote image"
        end
        raise SPF::Common::WrongRawDataReadingException unless byte_to_read.eql? raw_data.size

        raw_data
      end

      def parse_request_header(header)
        tmp = header.split(' ')
        [tmp[0], tmp[1].to_i]
      end

    end
  end
end
