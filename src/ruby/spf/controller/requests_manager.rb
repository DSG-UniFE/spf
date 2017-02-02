require 'timeout'
require 'concurrent'

require 'spf/common/logger'
require 'spf/common/validate'
require 'spf/common/exceptions'
require 'spf/common/extensions/fixnum'
require 'spf/common/tcpserver_strategy'

require_relative './application_configuration'


module SPF
  module Controller
    class RequestsManager < SPF::Common::TCPServerStrategy

    include SPF::Logging

      @@APPLICATION_CONFIG_DIR = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'etc', 'controller', 'app_configurations'))
      @@ALLOWED_COMMANDS = %q(service_policies dissemination_policy)

      @@DEFAULT_HOST = "localhost"
      @@DEFAULT_PORT = 52161

      # Timeouts
      @@DEFAULT_OPTIONS = {
        send_data_timeout: 5.seconds,
        receive_request_timeout: 5.seconds
      }

      def initialize(pigs, pigs_tree, host=@@DEFAULT_HOST, port=@@DEFAULT_PORT)
        super(host, port, self.class.name)

        @pigs = pigs
        @pigs_lock = Concurrent::ReadWriteLock.new
        @pigs_tree = pigs_tree
        @pigs_tree_lock = Concurrent::ReadWriteLock.new

        @app_conf = {}
        Dir.foreach(File.join(@@APPLICATION_CONFIG_DIR)) do |app_name|
          begin
            app_config_pwd = File.join(@@APPLICATION_CONFIG_DIR, app_name)
            next if File.directory? app_config_pwd
            @app_conf[app_name.to_sym] = ApplicationConfiguration::load_from_file(app_config_pwd)
            logger.info "*** #{self.class.name}: Added configuration for '#{app_name}' application ***"
          rescue ArgumentError => e
            logger.warn e.message
          rescue SPF::Common::Exceptions::ConfigurationError => e
            logger.warn e.message
          end
        end
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
        # User 3;{lat:=>44.838124,:lon=>11.619786};find "water"
        def handle_connection(user_socket)
          _, port, host = user_socket.peeraddr
          logger.info "*** #{self.class.name}: Received connection from #{host}:#{port} ***"

          header, body = receive_request(user_socket)
          if header.nil? || body.nil?
            logger.info "*** #{self.class.name}: Received wrong message from #{host}:#{port} ***"
            return
          end

          request, app_name, serv = parse_request_header(header)
          raise SPF::Common::Exceptions::WrongHeaderFormatException unless request.eql? "REQUEST"

          unless @app_conf.has_key? app_name.to_sym
            logger.error "*** #{self.class.name}: Received request for inexistent configuration ***"
            return
          end

          _, lat, lon, _ = parse_request_body(body)
          unless SPF::Common::Validate.latitude?(lat) && SPF::Common::Validate.longitude?(lon)
            logger.error "*** #{self.class.name}: Error in client GPS coordinates ***"
            return
          end

          pig = nil
          @pigs_tree_lock.with_read_lock do
            request = PigDS.new(:request, 0, 0, nil, lat.to_f, lon.to_f)
            pig = @pigs_tree.nearestNeighbourSearch(1, request)[0]
          end

          if pig.nil?
            logger.warn "*** #{self.class.name}: Could not find the nearest PIG (empty data structure?) ***"
            return
          end

          # TODO
          # ? If the nearest pig is down, send the request to another pig
          if pig.socket.nil?
            logger.warn "*** #{self.class.name}: socket to PIG #{pig.ip}:#{pig.port} is nil! ***"

            remove_pig(pig)
            return
          end

          if pig.updated
            send_app_configuration(app_name.to_sym, pig)
            pig.updated = false
            logger.info "*** #{self.class.name}: Sent app configuration to PIG #{pig.ip}:#{pig.port} ***"
          end

          send_data(pig, header, body)
          logger.info "*** #{self.class.name}: Sent data to PIG #{pig.ip}:#{pig.port} ***"

        rescue SPF::Common::Exceptions::WrongHeaderFormatException
          logger.warn "*** #{self.class.name}: Received header with wrong format from #{host}:#{port}! ***"
        rescue SPF::Common::Exceptions::UnreachablePig
          logger.warn "*** #{self.class.name}: Impossible connect to PIG #{pig.ip}:#{pig.port}! ***"
          pig.socket = nil
          remove_pig(pig)
        rescue Timeout::Error
          logger.warn "*** #{self.class.name}: Timeout send data to PIG #{pig.ip}:#{pig.port}! ***"
          pig.socket = nil
          remove_pig(pig)
        rescue IOError
          logger.warn "*** #{self.class.name}: Closed stream to PIG #{pig.ip}:#{pig.port}! ***"
          pig.socket = nil
          remove_pig(pig)
        rescue Errno::EHOSTUNREACH
          logger.warn "*** #{self.class.name}: PIG #{pig.ip}:#{pig.port} unreachable! ***"
          pig.socket = nil
          remove_pig(pig)
        rescue Errno::ECONNREFUSED
          logger.warn "*** #{self.class.name}: Connection refused by PIG #{pig.ip}:#{pig.port}! ***"
          pig.socket = nil
          remove_pig(pig)
        rescue Errno::ECONNRESET
          logger.warn "*** #{self.class.name}: Connection reset by PIG #{pig.ip}:#{pig.port}! ***"
          pig.socket = nil
          remove_pig(pig)
        rescue Errno::ECONNABORTED
          logger.warn "*** #{self.class.name}: Connection aborted by PIG #{pig.ip}:#{pig.port}! ***"
          pig.socket = nil
          remove_pig(pig)
        rescue Errno::ETIMEDOUT
          logger.warn "*** #{self.class.name}: Connection to PIG #{pig.ip}:#{pig.port} closed for timeout! ***"
          pig.socket = nil
          remove_pig(pig)
        rescue EOFError
          logger.warn "*** #{self.class.name}: PIG #{pig.ip}:#{pig.port} disconnected! ***"
          pig.socket = nil
          remove_pig(pig)
        rescue ArgumentError => e
          logger.warn e.message
        end

        def receive_request(user_socket)
          header = nil
          body = nil
          begin
            status = Timeout::timeout(@@DEFAULT_OPTIONS[:receive_request_timeout]) do
              _, port, host = user_socket.peeraddr
              header = user_socket.gets
              body = user_socket.gets
            end
          rescue SPF::Common::Exceptions::ReceiveRequestTimeout
            logger.warn  "*** #{self.class.name}: Receive request timeout to PIG #{host}:#{port}! ***"
          end
          [header, body]
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
          begin
            tmp = body.split(';')
            c = instance_eval(tmp[1])
            lat = c[:lat].to_s
            lon = c[:lon].to_s
            return [tmp[0], lat, lon, tmp[2]]
          rescue SyntaxError => se
            logger.warn  "*** #{self.class.name}: wrong request format received; request string was: #{body} ***"
          rescue => e
            logger.warn  "*** #{self.class.name}: wrong request format received; request string was: #{body} ***"
          end

          [nil, nil, nil, nil]
        end

        def send_app_configuration(app_name, pig)
          if @app_conf[app_name].nil?
            logger.error "*** #{self.class.name}: Could not find the configuration for application '#{app_name.to_s}' ***"
            raise ArgumentError, "*** #{self.class.name}: Application '#{app_name.to_s}' not found! ***"
          end

          if pig.applications[app_name].nil?
            # Configuration never sent to the pig before --> doing that now
            config = @app_conf[app_name].to_s.force_encoding(Encoding::UTF_8)
          else
            config = pig.applications[app_name].to_s.force_encoding(Encoding::UTF_8)
          end
          reprogram_body = "application \"#{app_name.to_s}\", #{config}"
          reprogram_header = "REPROGRAM #{reprogram_body.bytesize}"

          send_data(pig, reprogram_header, reprogram_body)

          if pig.applications[app_name].nil?
            pig.applications[app_name] = @app_conf[app_name]
          end
        end

        def send_data(pig, header, body)
          begin
            status = Timeout::timeout(@@DEFAULT_OPTIONS[:send_data_timeout]) do
              pig.socket.puts(header)
              pig.socket.puts(body)
              pig.socket.flush

              receive = pig.socket.gets
              receive.gsub!(/[^0-9a-z! ]/i, '')
              raise SPF::Common::Exceptions::UnreachablePig unless receive.eql? "REPROGRAM RECEIVED!" or receive.eql? "REQUEST RECEIVED!"

            end
          rescue Timeout::Error => e
            raise e
          rescue => e
            # puts e.class
            # puts e.message
            # puts e.backtrace
            raise SPF::Common::Exceptions::UnreachablePig
          end
        end

      def remove_pig(pig)
        @pigs_lock.with_write_lock do
          if @pigs.key?(pig.alias_name)
            @pigs.delete(pig)
            logger.warn  "*** #{self.class.name}: removed PIG #{pig.alias_name} from @pigs ***"
          end
        end
        @pigs_tree_lock.with_write_lock do
          @pigs_tree.remove(pig)
          logger.warn  "*** #{self.class.name}: removed PIG #{pig.alias_name} from @pigs_tree ***"
        end
      end

    end
  end
end
