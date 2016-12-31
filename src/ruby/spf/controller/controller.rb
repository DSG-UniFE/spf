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

      def initialize(host, port=DEFAULT_REQUESTS_PORT, conf_filename=@@DEFAULT_PIGS_FILE)
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
        Dir.foreach(File.join(@@APPLICATION_CONFIG_DIR)) do |app_name|
          app_config_pwd = File.join(@@APPLICATION_CONFIG_DIR, app_name)
          next if File.directory? app_config_pwd
          @app_conf[app_name.to_sym] = ApplicationConfiguration::load_from_file(app_config_pwd)[app_name.to_sym]
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

        # REQUEST participants/find_text
        # User 3;44.838124,11.619786;find "water"
        def handle_connection(user_socket)
          _, port, host = user_socket.peeraddr
          logger.info "*** Controller: Received connection from #{host}:#{port} ***"

          header, body = receive_request(user_socket)
          if header.nil? or body.nil?
            logger.info "*** Controller: Received wrong message from #{host}:#{port} ***"
            return
          end

          request, app_name, serv = parse_request_header(header)
          raise SPF::Common::Exceptions::WrongHeaderFormatException unless request.eql? "REQUEST"

          unless @app_conf.has_key? app_name.to_sym
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
          # TODO
          # ? If the nearest pig is down, send the request to another pig
          if pig_socket.nil? or pig_died?(pig[:ip], pig[:port])
            # TODO
            # ? Se il PIG muore rimuoviamo la configurazione
            pig_socket = rescue_closed_socket(pig_socket, pig, app_name.to_sym)
            @pig_connections["#{pig[:ip]}:#{pig[:port]}".to_sym] = pig_socket
          end

          if pig[:applications][app_name.to_sym].nil?
            # Configuration never sent to the pig before --> doing that now
            send_app_configuration(app_name.to_sym, pig_socket, pig)
          end

          begin
            pig_socket.puts(header)
            pig_socket.puts(body)
            logger.info "*** Controller: sent request to PIG #{pig[:ip]}:#{pig[:port]} ***"
          rescue Errno::ECONNRESET, Errno::EPIPE, Errno::EHOSTUNREACH, Errno::ECONNREFUSED
            pig_socket = rescue_closed_socket(pig_socket, pig, app_name.to_sym)
            @pig_connections["#{pig[:ip]}:#{pig[:port]}".to_sym] = pig_socket
            retry
          end

        rescue Timeout::Error
          logger.warn  "*** Controller: Timeout connect to pigs #{host}:#{port}! ***"
        rescue SPF::Common::Exceptions::WrongHeaderFormatException
          logger.warn "*** Controller: Received header with wrong format from #{host}:#{port}! ***"
        rescue SPF::Common::Exceptions::UnreachablePig
          logger.warn "*** Controller: Impossible connect to pig #{pig[:ip]}:#{pig[:port]}! ***"
        rescue Errno::EHOSTUNREACH
          logger.warn "*** Controller: PIG #{pig[:ip]}:#{pig[:port]} unreachable! ***"
        rescue Errno::ECONNREFUSED
          logger.warn  "*** Controller: Connection refused by PIG #{pig[:ip]}:#{pig[:port]}! ***"
        rescue Errno::ECONNRESET
          logger.warn "*** Controller: Connection reset by PIG #{pig[:ip]}:#{pig[:port]}! ***"
        rescue Errno::ECONNABORTED
          logger.warn "*** Controller: Connection aborted by PIG #{pig[:ip]}:#{pig[:port]}! ***"
        rescue Errno::ETIMEDOUT
          logger.warn "*** Controller: Connection to PIG #{pig[:ip]}:#{pig[:port]} closed for timeout! ***"
        rescue EOFError
          logger.warn "*** Controller: PIG #{pig[:ip]}:#{pig[:port]} disconnected! ***"
        rescue ArgumentError => e
          logger.warn e.message
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
          ensure
            user_socket.close
          end
          [header, body]
        end

        def connect_to_pig(host, port, connection_table)
          status = Timeout::timeout(@@DEFAULT_OPTIONS[:pig_connect_timeout]) do
            attempts = 3
            begin
              pig_socket = TCPSocket.new(host, port)
              # TODO
              # Keeping a connection alive over time when there is no traffic being sent
              # pig_socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_KEEPALIVE, true)
              logger.info "*** Controller: Connected to PIG #{host}:#{port} ***"
              connection_table["#{host}:#{port}".to_sym] = pig_socket
              pig_socket
            rescue
              attempts -= 1
              attempts > 0 ? retry : (fail SPF::Common::Exceptions::UnreachablePig)
            end
          end
        end

        # Open socket to all pigs in the @pigs list
        def connect_to_pigs(connection_table)
          @pigs_list.each do |pig|
            begin
              connect_to_pig(pig[:ip], pig[:port], connection_table)
            rescue SPF::Common::Exceptions::UnreachablePig
              logger.warn "*** Controller: Impossible connect to pig #{pig[:ip]}:#{pig[:port]}! ***"
            end
          end
        end

        def read_reconf_template(template_filename)
          @reconf_template = File.new(template_filename, 'r').read
        end

        # REQUEST participants/find_text
        def parse_request_header(header)
          tmp = header.split(' ')
          app_name, serv = tmp[1].split('/')
          [tmp[0], app_name, serv]
        end

        # User 3;44.838124,11.619786;find "water"
        def parse_request_body(body)
          tmp = body.split(';')
          lat, lon = tmp[1].split(',')
          [tmp[0], lat, lon, tmp[2]]
        end

        def send_app_configuration(app_name, socket, pig)
          if @app_conf[app_name].nil?
            logger.error "*** Controller: Could not find the configuration for application '#{app_name.to_s}' ***"
            raise ArgumentError, "*** Controller: Application '#{app_name.to_s}' not found! ***"
          end

          config = @app_conf[app_name].to_s.force_encoding(Encoding::UTF_8)
          reprogram_body = "application \"#{app_name.to_s}\", #{config}"
          reprogram_header = "REPROGRAM #{reprogram_body.bytesize}"

          status = Timeout::timeout(@@DEFAULT_OPTIONS[:pig_connect_timeout]) do
            _, port, host = socket.peeraddr
            socket.puts(reprogram_header)
            socket.puts(reprogram_body)
            logger.info "*** Controller: Sent configuration info for app '#{app_name.to_s}' ***"
            pig[:applications][app_name] = @app_conf[app_name]
          end
        end

        def rescue_closed_socket(pig_socket, pig, app_name)
          logger.warn "*** Controller: Socket to PIG #{pig[:ip]}:#{pig[:port]} disconnected - Attempting reconnection ***"
          pig_socket = connect_to_pig(pig[:ip], pig[:port], @pig_connections)

          send_app_configuration(app_name, pig_socket, pig)
          pig_socket
        end

        def pig_died?(ip, port, seconds=1)
          Timeout::timeout(seconds) do
            begin
              TCPSocket.new(ip, port).close
              false
            rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
              true
            end
          end
        rescue Timeout::Error
          true
        end

    end
  end
end
