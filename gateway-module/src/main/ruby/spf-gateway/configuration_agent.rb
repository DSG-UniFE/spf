require 'timeout'
require 'yaml'
require 'spf-common/controller'


module SPF
  module Exceptions
    # New exception types
    class HeaderReadTimeout < Exception; end
    class ProgramReadTimeout < Exception; end
    class WrongHeaderFormatException < Exception; end
  end

  module Gateway

    class ConfigurationAgent < SPF::Common::Controller

      # Timeouts
      DEFAULT_OPTIONS = {
        header_read_timeout:  10,     # 10 seconds
        program_read_timeout: 2 * 60, # 2 minutes
      }

      # Get ASCII/UTF-8 code for newline character
      # NOTE: the following code is uglier but should be more portable and
      # robust than a simple '\n'.ord
      NEWLINE = '\n'.unpack('C').first

      # NOTE: Added @service_manager param to initialize the Configuration Agent, needed in new_service_request
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
          logger.info "*** Received connection from #{host}:#{port} ***"

          # try to read first line
          first_line = ""
          status = Timeout::timeout(@ca_conf[:header_read_timeout],
                                    SPF::Exceptions::HeaderReadTimeout) do
            first_line = socket.gets
          end

          # parse (tokenize, actually) the header line
          header = first_line.split(" ")

          case header[0]
            when "REPROGRAM"

              # REPROGRAM application <app name>
              # <new-configuration>
              reprogram(socket)

            when "REQUEST"

              # REQUEST participants/find
              # User 3;44.838124,11.619786;find "water"
              application_name, service_name = header[1].split("/")
              new_service_request(application_name.to_sym, service_name.to_sym, socket)

          else
            raise SPF::Exceptions::WrongHeaderFormatException
          end

        rescue SPF::Exceptions::HeaderReadTimeout => e
          logger.warn  "*** Timeout reading header from #{host}:#{port}! ***"
          raise e
        rescue SPF::Exceptions::ProgramReadTimeout => e
          logger.warn  "*** Timeout reading program from #{host}:#{port}! ***"
          raise e
        rescue SPF::Exceptions::WrongHeaderFormatException => e
          logger.error "*** Received header with wrong format from #{host}:#{port}! ***"
          raise e
        rescue ArgumentError => e
          logger.error "*** #{host}:#{port} sent wrong program size format! ***"
          raise e
        rescue EOFError => e
          logger.error "*** #{host}:#{port} disconnected! ***"
          raise e
        ensure
          socket.close
        end

       
        def new_service_request(application_name, service_name, socket)
          # find service
          svc = @service_manager.get_service_by_name(application_name, service_name)
          return if svc.nil?

          # bring service up again if down
          @service_manager.restart_service(svc) unless svc.active?

          # update service
          svc.register_request(socket)
        end

        private

          def reprogram(socket)
            # read the new configuration
            received = ""
            status = Timeout::timeout(@ca_conf[:program_read_timeout],
                                      SPF::Exceptions::ProgramReadTimeout) do
            loop do
                line = socket.gets
                break if line.nil?
                received += line
              end
            end

            @pig_conf.reprogram(received)
          end

    end
  end
end
