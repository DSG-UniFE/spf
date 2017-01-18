require 'timeout'

require 'spf/common/controller'
require 'spf/common/extensions/fixnum'
require 'spf/common/exceptions'


module SPF
  module Gateway

    class ConfigurationAgent < SPF::Common::LoopConnector

      # Timeouts
      DEFAULT_OPTIONS = {
        header_read_timeout:  5.seconds,
        request_read_timeout: 10.seconds,
        reprogram_read_timeout: 10.seconds
      }

      # Get ASCII/UTF-8 code for newline character
      # NOTE: the following code is uglier but should be more portable and
      # robust than a simple '\n'.ord
      NEWLINE = '\n'.unpack('C').first

      def initialize(service_manager, host, port, configuration, opts = {})
        super(host, port)
        @pig_conf = configuration # PIGConfiguration object
        @ca_conf = DEFAULT_OPTIONS.merge(opts)
        @service_manager = service_manager
      end


      private

      def handle_connection(socket)
        # get client address
        _, port, host = socket.peeraddr
        logger.info "*** PIG::ConfigurationAgent: registering with SPF Controller ***"
        
        #TODO: SEND REGISTRATION INFO AND WAIT FOR ACK
        registration = {}
        regitration[:alias] = @pig_conf.alias
        regitration[:gps_lat] = @pig_conf.location[:gps_lat]
        regitration[:gps_lon] = @pig_conf.location[:gps_lon]
        registration.to_yaml!
        socket.puts "REGISTER PIG #{registration.bytesize}"
        socket.puts registration
        
        response = socket.gets
        return if response != "OK!"

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
              logger.info "*** Pig: Received REPROGRAM ***"
              conf_size = header[1].to_i
              reprogram(conf_size, socket)

            when "REQUEST"

              # REQUEST participants/find_text
              # User 3;44.838124,11.619786;find "water"
              logger.info "*** Pig: Received REQUEST ***"
              request_line = ""
              application_name, service_name = header[1].split("/")
              status = Timeout::timeout(@ca_conf[:request_read_timeout],
                                        SPF::Common::Exceptions::HeaderReadTimeout) do
                request_line = socket.gets
              end
              new_service_request(application_name.to_sym, service_name.to_sym, request_line)

            else
              raise SPF::Common::Exceptions::WrongHeaderFormatException
          end
        end
      rescue SPF::Common::Exceptions::ProgramReadTimeout => e
        logger.warn  "*** Pig: Timeout reading program from #{host}:#{port}! ***"
        #raise e
      rescue SPF::Common::Exceptions::WrongHeaderFormatException => e
        logger.error "*** Pig: Received header with wrong format from #{host}:#{port}! ***"
        #raise e
      rescue ArgumentError => e
        logger.error "*** Pig: #{host}:#{port} sent wrong program size format! ***"
        #raise e
      rescue EOFError => e
        logger.error "*** Pig: #{host}:#{port} disconnected! ***"
        #raise e
      ensure
        socket.close
      end

      def new_service_request(application_name, service_name, request_line)
        # find service
        svc = @service_manager.get_service_by_name(application_name, service_name)
        return if svc.nil?

        # bring service up again if down
        @service_manager.restart_service(svc) unless svc.active?

        # update service
        begin
          svc.register_request(request_line)
        rescue SPF::Common::Exceptions::WrongServiceRequestStringFormatException => e
          logger.error e.message
        end
      end

      def reprogram(conf_size, socket)
        # read the new configuration
        conf = ""
        status = Timeout::timeout(@ca_conf[:reprogram_read_timeout],
                                  SPF::Common::Exceptions::ProgramReadTimeout) do
          conf = socket.gets
          raise SPF::Common::Exceptions::WrongHeaderFormatException, "Configuration bytesize mismatch" if conf.bytesize != (conf_size + 1)
        end
        @pig_conf.reprogram(conf)
      end

    end
  end
end
