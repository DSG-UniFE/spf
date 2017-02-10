require 'socket'
require 'concurrent'
require 'spf/common/logger'
require 'spf/common/validate'
require 'spf/common/exceptions'
require 'spf/common/extensions/fixnum'


module SPF
  module Gateway
    class SensorReceiver

        include SPF::Logging

    	def initialize(pool, service_manager, sensor_socket)

    		@@DEFAULT_TIMEOUT = 5.seconds
    		@pool = pool
    		@service_manager = service_manager
    		@socket = sensor_socket

    	end

    	def run
 			_, port, host = @socket.peeraddr
          logger.info "*** #{self.class.name}: Received connection from #{host}:#{port} ***"

          header, raw_data = receive_request(@socket)
          if header.nil? || raw_data.nil?
            logger.info "*** #{self.class.name}: Received wrong message from #{host}:#{port} ***"
            return
          end

          request, byte_to_read = parse_request_header(header)

          raise SPF::Common::Exceptions::WrongRawDataHeaderException unless request.eql? "IMAGE"

          raise SPF::Common::Exceptions::WrongRawDataReadingException unless byte_to_read.eql? raw_data.size

          @service_manager.with_pipelines_interested_in(raw_data) do |pl|
            @pool.post do
              begin
                pl.process(raw_data, source)
              rescue => e
                puts e.message
                puts e.backtrace
                raise e
              end
            end
          end

          rescue SPF::Common::Exceptions::WrongRawDataHeaderException
          	logger.warn "*** #{self.class.name}: Received header with wrong format from #{host}:#{port}! ***"
          rescue SPF::Common::Exceptions::WrongRawDataReadingException
          	logger.warn "*** #{self.class.name}: Received byte_size different from raw_data.size: #{byte_to_read} | #{raw_data.size}***"


    	end

    	def receive_request(socket)
          header = nil
          body = nil
          begin
            status = Timeout::timeout(5) do
              _, port, host = socket.peeraddr
              header = socket.gets
              body = socket.gets
              puts "HEADER: #{header}"
              puts "BODY: #{body}"
            end
          rescue SPF::Common::Exceptions::ReceiveRequestTimeout
            logger.warn  "*** #{self.class.name}: Receive request timeout to PIG #{host}:#{port}! ***"
          end
          [header, body]
        end

        def parse_request_header(header)
          tmp = header.split(' ')
          [tmp[0], tmp[1]]
        end


    end
  end
end
