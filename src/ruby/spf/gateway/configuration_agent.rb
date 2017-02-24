require 'timeout'
require 'socket'
require 'json'

require 'spf/common/extensions/fixnum'
require 'spf/common/exceptions'
require 'spf/common/loop_connector'


module SPF
  module Gateway

    class ConfigurationAgent < SPF::Common::LoopConnector

      include Socket::Constants

      DEFAULT_HOST = '127.0.0.1'
      DEFAULT_PORT = 52160

      # Timeouts
      DEFAULT_OPTIONS = {
        header_read_timeout:      5.seconds,
        request_read_timeout:     10.seconds,
        reprogram_read_timeout:   10.seconds
      }

      # Get ASCII/UTF-8 code for newline character
      # NOTE: the following code is uglier but should be more portable and
      # robust than a simple '\n'.ord
      NEWLINE = '\n'.unpack('C').first

      def initialize(service_manager, configuration, remote_host=DEFAULT_HOST,
                      remote_port=DEFAULT_PORT, opts = {})
        super(remote_host, remote_port, self.class.name)

        @service_manager = service_manager
        @pig_conf = configuration # PIGConfiguration object
        @ca_conf = DEFAULT_OPTIONS.merge(opts)
      end


      private

        def handle_connection(socket, host, port)
          # set Socket KEEP_ALIVE: after 60s inactivity send up to 10 probes with 5s interval
          if [:SOL_SOCKET, :SO_KEEPALIVE].all? {|c| Socket.const_defined? c}
            socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_KEEPALIVE, true)
            if [:SOL_TCP, :TCP_KEEPIDLE, :TCP_KEEPINTVL, :TCP_KEEPCNT].all? {|c| Socket.const_defined? c}
              socket.setsockopt(Socket::SOL_TCP, Socket::TCP_KEEPIDLE, 60)
              socket.setsockopt(Socket::SOL_TCP, Socket::TCP_KEEPINTVL, 10)
              socket.setsockopt(Socket::SOL_TCP, Socket::TCP_KEEPCNT, 5)
            end
            logger.info "*** #{self.class.name}: set keep-alive options for the TCP connection with the SPF Controller ***"
          end

          logger.info "*** #{self.class.name}: begin registration with the SPF Controller ***"

          # create registration object
          registration = {}

          registration[:alias_name] = @pig_conf.alias_name
          registration[:lat] = @pig_conf.location[:lat]
          registration[:lon] = @pig_conf.location[:lon]
          registration = registration.to_json

          # register PIG with the SPF Controller
          socket.puts "REGISTER PIG #{registration.bytesize}"
          socket.puts registration

          response = socket.gets
          unless response.start_with? "OK!"
            logger.warn "*** #{self.class.name}: registering with the SPF Controller FAILED with response #{response} ***"
            return
          end

          logger.info "*** #{self.class.name}: registration with the SPF Controller SUCCEEDED ***"

          loop do
            # try to read first line
            first_line = socket.gets
            raise SPF::Common::Exceptions::WrongHeaderFormatException if first_line.nil?
            # parse (tokenize, actually) the header line
            header = first_line.split(" ")

            case header[0]
              when "REPROGRAM"
                # REPROGRAM <conf_bytesize>
                # application/modify_application <app_name> <configuration>
                logger.info "*** #{self.class.name}: Received REPROGRAM ***"
                socket.puts "REPROGRAM RECEIVED!"

                conf_size = header[1].to_i
                reprogram(conf_size, socket)
              when "REQUEST"
                # REQUEST participants/find_text
                # User 3;44.838124,11.619786;find "water"
                request_line = ""
                application_name, service_name = header[1].split("/")
                logger.info "*** #{self.class.name}: Received REQUEST for #{application_name}/#{service_name} ***"
                status = Timeout::timeout(@ca_conf[:request_read_timeout],
                                          SPF::Common::Exceptions::HeaderReadTimeout) do
                  request_line = socket.gets
                end
                socket.puts "REQUEST RECEIVED!"

                new_service_request(application_name.to_sym, service_name.to_sym, request_line)
              else
                raise SPF::Common::Exceptions::WrongHeaderFormatException
            end
          end
        rescue Timeout::Error
          logger.warn  "*** #{self.class.name}: Timeout error from #{host}:#{port}! ***"
        rescue SPF::Common::Exceptions::ProgramReadTimeout
          logger.warn  "*** #{self.class.name}: Timeout reading program from #{host}:#{port}! ***"
        rescue SPF::Common::Exceptions::WrongHeaderFormatException
          logger.error "*** #{self.class.name}: Received header with wrong format from #{host}:#{port}! ***"
        rescue Errno::ETIMEDOUT
          logger.error "*** #{self.class.name}: Connection with SPF Controller #{host}:#{port} timed out! ***"
        rescue ArgumentError
          logger.error "*** #{self.class.name}: #{host}:#{port} sent wrong program size format! ***"
        rescue EOFError
          logger.error "*** #{self.class.name}: #{host}:#{port} disconnected! ***"
        rescue => e
          logger.error e.message
          logger.error e.backtrace
        ensure
          socket.close
        end

        def new_service_request(application_name, service_name, request_line)
          # find service
          svc = @service_manager.get_service_by_name(application_name, service_name)
          return if svc.nil?

          # bring service up again if down
          @service_manager.restart_service(svc) unless svc.active?
          begin
            req_string = request_line.split(";")[2]
            raise SPF::Common::Exceptions::WrongServiceRequestStringFormatException,
              "received request #{request_line} with a wrong format" if req_string.nil? || req_string.empty?
            svc.register_request(request_line)
          rescue SPF::Common::Exceptions::WrongServiceRequestStringFormatException => e
            logger.error e.message
          rescue SPF::Common::Exceptions::PipelineNotActiveException => e
            logger.error e.message
          end
        end

        def reprogram(conf_size, socket)
          # read the new configuration
          conf = ""
          status = Timeout::timeout(@ca_conf[:reprogram_read_timeout],
                                    SPF::Common::Exceptions::ProgramReadTimeout) do
            conf = socket.gets
            raise SPF::Common::Exceptions::WrongHeaderFormatException,
              "Configuration bytesize mismatch" if conf.bytesize != (conf_size + 1)
          end
          @pig_conf.reprogram(conf)
        end

    end
  end
end
