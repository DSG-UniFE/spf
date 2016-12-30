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

      DEFAULT_REQUESTS_PORT = 52161

      @@DEFAULT_PIGS_FILE = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'etc', 'controller', 'pigs'))
      @@APPLICATION_CONFIG_DIR = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'etc', 'controller', 'app_configurations'))
      @@ALLOWED_COMMANDS = %q(service_policies dissemination_policy)

      # Timeouts
      @@DEFAULT_OPTIONS = {
        pig_connect_timeout: 5.seconds,
        receive_request_timeout: 5.seconds
      }

      def initialize(host, port = DEFAULT_REQUESTS_PORT, conf_filename = @@DEFAULT_PIGS_FILE)
        super(host, port)

        @pigs_list = Configuration::load_from_file(conf_filename)
        @pigs_list.each do |pig|
          pig[:applications] = {}
        end
        @pigs_tree = Geokdtree::Tree.new(2)
        @pigs_list.each do |pig|
          @pigs_tree.insert([pig['gps_lat'], pig['gps_lon']], pig)
        end

        @app_conf = {}
        Dir.foreach(File.join(@@APPLICATION_CONFIG_DIR)) do |app|
          app_config_pwd = File.join(@@APPLICATION_CONFIG_DIR, app)
          next if File.directory? app_config_pwd
          @app_conf[app.to_sym] = ApplicationConfiguration::load_from_file(app_config_pwd)[app.to_sym]
        end

        @pig_connections = {}
        connect_to_pigs(@pig_connections)
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

        # REQUEST participants/find
        # User 3;44.838124,11.619786;find "water"
        def handle_connection(user_socket)
          begin
            _, port, host = user_socket.peeraddr
            logger.info "*** Controller: Received connection from #{host}:#{port} ***"

            header, body = receive_request(user_socket)
            if header.nil? or body.nil?
              logger.info "*** Controller: Received wrong message from #{host}:#{port} ***"
              return
            end

            request, app, serv = parse_request_header(header)
            raise SPF::Common::Exceptions::WrongHeaderFormatException unless request.eql? "REQUEST"

            unless @app_conf.has_key? app.to_sym
              logger.error "*** Controller: Received request for inexistent configuration ***"
              return
            end

            _, lat, lon, _ = parse_request_body(body)
            unless SPF::Common::Validate.latitude?(lat) && SPF::Common::Validate.longitude?(lon)
              logger.error "*** Controller: Error in client GPS coordinates ***"
              return
            end

            result = @pigs_tree.nearest([lat.to_f, lon.to_f])
            if result.nil?
              logger.fatal "*** Controller: Could not find the nearest PIG (empty data structure?) ***"
              return
            end

            pig = result.data
            puts "NEAREST PIG: #{pig}"
            pig_socket = @pig_connections["#{pig[:ip]}:#{pig[:port]}".to_sym]
            if pig_socket.nil? or pig_socket.closed?
              pig_socket = rescue_closed_socket(pig_socket, pig, app)
              @pig_connections["#{pig[:ip]}:#{pig[:port]}".to_sym] = pig_socket
            end

            if pig[:applications][app.to_sym].nil?
              # Configuration never sent to the pig before --> doing that now
              send_app_configuration(app.to_sym, pig_socket)
              pig[:applications][app.to_sym] = @app_conf[app.to_sym]    # Move this call inside send_app_configuration?
            end
  
            begin
              pig_socket.puts(header)
              pig_socket.puts(body)
              logger.info "*** Controller: sent request to PIG #{pig[:ip]}:#{pig[:port]} ***"
            rescue Errno::ECONNRESET, Errno::EPIPE
              pig_socket = rescue_closed_socket(pig_socket, pig, app)
              @pig_connections["#{pig[:ip]}:#{pig[:port]}".to_sym] = pig_socket
              retry
            end
          
          rescue SPF::Common::Exceptions::PigConnectTimeout
            logger.warn  "*** Controller: Timeout connect to pigs #{host}:#{port}! ***"
            # raise e
          rescue SPF::Common::Exceptions::WrongHeaderFormatException => e
            logger.warn "*** Controller: Received header with wrong format from #{host}:#{port}! ***"
            # raise e
          rescue SPF::Common::Exceptions::UnreachablePig => e
            logger.warn e
            # logger.warn  "*** Controller: Timeout connect to pigs #{host}:#{port}! ***"
            # raise e
          rescue EOFError
            logger.info "*** Controller: #{host}:#{port} disconnected ***"
          rescue ArgumentError => e
            logger.error e
            # raise e
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
            logger.warn  "*** Controller: Timeout connect to pigs #{host}:#{port}! ***"
            raise e
          ensure
            user_socket.close
          end
          [header, body]
        end

        def connect_to_pig(host, port, connection_table)
          status = Timeout::timeout(@@DEFAULT_OPTIONS[:pig_connect_timeout],
                                    SPF::Common::Exceptions::PigConnectTimeout) do
            attempts = 3
            begin
              pig_socket = TCPSocket.new(host, port)
              connection_table["#{host}:#{port}".to_sym] = pig_socket
              return pig_socket
            # rescue SPF::Common::Exceptions::PigConnectTimeout => e
            #   logger.warn  "*** Controller: Timeout connect to pigs #{host}:#{port}! ***"
            #   raise e
            # rescue Errno::ECONNREFUSED
            #   logger.warn  "*** Controller: Connect refused to pigs #{host}:#{port}! ***"
            # end
            rescue
              attempts -= 1
              attempts > 0 ? retry : (fail SPF::Common::Exceptions::UnreachablePig, "*** Controller: Impossible connect to pig #{host}:#{port}! ***")
            end
          end
        end

        # Open socket to all pigs in the @pigs list
        def connect_to_pigs(connection_table)
          @pigs_list.each do |pig|
            status = Timeout::timeout(@@DEFAULT_OPTIONS[:pig_connect_timeout],
                                      SPF::Common::Exceptions::PigConnectTimeout) do
              begin
                pig_socket = TCPSocket.new(pig[:ip], pig[:port])
                connection_table["#{pig[:ip]}:#{pig[:port]}".to_sym] = pig_socket
              rescue SPF::Common::Exceptions::PigConnectTimeout => e
                logger.warn  "*** Controller: Timeout connect to pigs #{pig[:ip]}:#{pig[:port]}! ***"
                raise e
              rescue Errno::ECONNREFUSED
                logger.warn  "*** Controller: Connect refused to pigs #{pig[:ip]}:#{pig[:port]}! ***"
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
          app, serv = tmp[1].split('/')
          [tmp[0], app, serv]
        end

        # User 3;44.838124,11.619786;find "water"
        def parse_request_body(body)
          tmp = body.split(';')
          lat, lon = tmp[1].split(',')
          [tmp[0], lat, lon, tmp[2]]
        end

        def send_app_configuration(app, socket)
          if @app_conf[app].nil?
            logger.error "*** Controller: Could not find the configuration for application #{app.to_s} ***"
            raise ArgumentError, "*** Controller: Application #{app.to_s} not found! ***"
          end

          config = @app_conf[app].to_s.force_encoding(Encoding::UTF_8)
          app = "application \"#{app.to_s}\", #{config}"
          reprogram = "REPROGRAM #{app.bytesize}"

          status = Timeout::timeout(@@DEFAULT_OPTIONS[:pig_connect_timeout],
                                    SPF::Common::Exceptions::PigConnectTimeout) do
            begin
              _, port, host = socket.peeraddr
              socket.puts(reprogram)
              socket.puts(app)
              logger.info "*** Controller: Sent configuration info for app #{app.to_s} ***"
            rescue SPF::Common::Exceptions::PigConnectTimeout => e
              logger.warn  "*** Controller: Timeout connect to pigs #{host}:#{port}! ***"
              raise e
            rescue Errno::ECONNREFUSED
              logger.warn  "*** Controller: Connect refused to pigs #{host}:#{port}! ***"
            end
          end
        end
        
        def rescue_closed_socket(pig_socket, pig, app)
          logger.warn "*** Controller: Socket to PIG #{pig[:ip]}:#{pig[:port]} disconnected - Attempting reconnection ***"
          pig_socket = connect_to_pig(pig[:ip], pig[:port], @pig_connections)

          send_app_configuration(app.to_sym, pig_socket)
          pig[:applications][app.to_sym] = @app_conf[app.to_sym]    # Move this call inside send_app_configuration?
          pig_socket
        end

    end
  end
end
