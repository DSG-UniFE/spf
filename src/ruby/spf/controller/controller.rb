require 'timeout'
require 'spf/common/controller'
require 'spf/common/logger'
require 'spf/common/validate'
require 'spf/common/exceptions'
require 'spf/common/extensions/fixnum'
require 'geokdtree'

require_relative './configuration'
require_relative './application_configuration'


module SPF
  module Controller
    include SPF::Logging

    class Controller < SPF::Common::Controller

      @@ALLOWED_COMMANDS = %q(service_policies dissemination_policy)
      @@APPLICATION_CONFIG_DIR = File.join('etc', 'controller', 'app_configurations')
      # Timeouts
      @@DEFAULT_OPTIONS = {
        pig_connect_timeout: 5.seconds,
        receive_request_timeout: 5.seconds
      }

      def initialize(host, port, conf_filename)
        @pigs_list = Configuration::load_from_file(conf_filename)

        @pigs_list.each do |pig|
          pig['applications'.to_sym] = {}
        end

        @pigs_tree = Geokdtree::Tree.new(2)
        @pigs_list.each do |pig|
          @pigs_tree.insert([pig['gps_lat'], pig['gps_lon']], pig)
        end

        @pig_connections = {}
        connect_to_pigs(@pig_connections)

        @app_conf = {}
        Dir.foreach(File.join(@@APPLICATION_CONFIG_DIR)) do |app|
          app_config_pwd = File.join(@@APPLICATION_CONFIG_DIR, app)
          next if File.directory? app_config_pwd
          @app_conf[app] = ApplicationConfiguration::load_from_file(app_config_pwd)
        end

        super(host, port)
      end

      def change_application_configuration(app_name, command)

        commands.each do |k,v|
          case k
          when /add_(.+)/
            break unless @@ALLOWED_COMMANDS.include? $1
            to_send=<<-END
            REPROGRAM #{app_name}
              add_#{$1}: #{v}
            END

          when /change_(.+)/
            break unless @@ALLOWED_COMMANDS.include? $1
            to_send=<<-END
            REPROGRAM #{app_name}
              change_#{$1}: #{v}
            END
          end
        end
      end

      private

        # def run(opts = {})
        #   send requests to the PIG
        #   first_req = ""
        #   second_req = ""
        #   third_req = ""
        #   sleep 3
        #   Thread.new { SPF::Request.new(@iot_address, @iot_port, first_req).run }
        #   sleep 10
        #   Thread.new { SPF::Request.new(@iot_address, @iot_port, second_req).run }
        #   sleep 10
        #   Thread.new { SPF::Request.new(@iot_address, @iot_port, third_req).run }
        # end

        # REQUEST participants/find
        # User 3;44.838124,11.619786;find "water"
        def handle_connection(user_socket)
          begin
            _, port, host = user_socket.peeraddr
            logger.info "*** Received connection from #{host}:#{port}"

            header, body = receive_request(user_socket)
            if header.nil? or body.nil?
              logger.info "*** Received wrong message from #{host}:#{port}"
              return
            end

            request, app, serv = parse_request_header(header)

            raise SPF::Common::Exceptions::WrongHeaderFormatException unless request.eql? "REQUEST"

            _, lat, lon, _ = parse_request_body(body)
            unless SPF::Common::Validate.latitude?(lat) && SPF::Common::Validate.longitude?(lon)
              logger.error "Error in client GPS coordinates"
              return
            end

            result = @pigs_tree.nearest([lat.to_f, lon.to_f])
            if result.nil?
              logger.fatal "Could not find the nearest PIG (empty data structure?)"
              return
            end

            pig = result.data.inspect
            puts "#{pig}"
            pig_socket = @pig_connections[(pig[:ip] + ":" + pig[:port].to_s).to_sym]      # check
            if pig_socket.nil? or pig_socket.closed?
              pig_socket = TCPSocket.new(pig[:ip], pig[:port])
              @pig_connections[(pig[:ip] + ":" + pig[:port].to_s).to_sym] = pig_socket
            end

            send_app_configuration(app.to_sym, pig_socket) unless pig[:applications].has_key?(app.to_sym)

            pig_socket.puts(header)
            pig_socket.puts(body)

          rescue SPF::Common::Exceptions::WrongHeaderFormatException => e
            logger.error "*** Received header with wrong format from #{host}:#{port}! ***"
            raise e
          rescue EOFError
            logger.info "*** #{host}:#{port} disconnected"
          rescue ArgumentError

          end
        end

        def receive_request(user_socket)
          header = nil
          body = nil
          begin
            _, port, host = user_socket.peeraddr
            header = user_socket.gets
            body = user_socket.gets
          rescue SPF::Common::Exceptions::ReceiveRequestTimeout => e
            logger.warn  "*** Timeout connect to pigs #{host}:#{port}! ***"
            raise e
          ensure
            user_socket.close
          end
          [header, body]
        end

        # Open socket to all pigs in the @pigs list
        def connect_to_pigs(connection_table)
          @pigs_list.each do |pig|
            status = Timeout::timeout(@@DEFAULT_OPTIONS[:pig_connect_timeout],
                                      SPF::Common::Exceptions::PigConnectTimeout) do
              begin
                pig_socket = TCPSocket.new(pig[:ip], pig[:port])
                connection_table[(pig[:ip] + ":" + pig[:port].to_s).to_sym] = pig_socket
              rescue SPF::Common::Exceptions::PigConnectTimeout => e
                logger.warn  "*** Timeout connect to pigs #{pig[:ip]}:#{pig[:port]}! ***"
                raise e
              rescue Errno::ECONNREFUSED
                logger.warn  "*** Connect refused to pigs #{pig[:ip]}:#{pig[:port]}! ***"
              end
            end
          end
        end

        def read_reconf_template(template_filename)
          @reconf_template = File.new(template_filename, 'r').read
        end

        # REQUEST participants/find
        def parse_request_header(header)
          tmp = header.split(' ')
          [tmp[0], tmp[1].split('/')]
        end

        # User 3;44.838124,11.619786;find "water"
        def parse_request_body(body)
          tmp = body.split(';')
          lat, lon = tmp[1].split(',')
          [tmp[0], lat, lon, tmp[2]]
        end

        def send_app_configuration (app, socket)
          if @app_conf[app].nil?
            logger.error "Could not find the configuration for application #{app.to_s}"
            raise ArgumentError, "Application #{app.to_s} not found!"
          end

          config = @app_conf[app].to_s.force_encoding(Encoding::UTF_8)
          reprogram = "REPROGRAM application \"#{config.bytesize}\""
          app = "application \"#{app.to_s}\",\n#{config}"

          socket.puts(reprogram)
          socket.puts(app)
        end

    end
  end
end
