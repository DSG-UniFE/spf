require 'concurrent'
require 'sinatra/base'

require 'spf/common/logger'
require 'spf/common/exceptions'
require 'spf/common/extensions/fixnum'

require_relative './configuration'
# require_relative './sinatra_ssl'

module SPF
  module Controller
    class HttpsInterface < Sinatra::Base

      include SPF::Logging

      # CERTIFICATE_DIR = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'resources', 'certificates'))

      # Load Controller configuration
      conf_filename_path = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'etc', 'controller', 'configuration'))
      begin
        @config = Configuration::load_from_file(conf_filename_path)
      rescue ArgumentError => e
        logger.error "*** #{self.class.name}: #{e.message} ***"
        exit
      rescue SPF::Common::Exceptions::ConfigurationError => e
        logger.error "*** #{self.class.name}: #{e.message} ***"
        exit
      end

      set :title, "SPF Controller"
      set :server, %w[webrick]
      # set :ssl_certificate, "#{CERTIFICATE_DIR}/cert.crt"
      # set :ssl_key, "#{CERTIFICATE_DIR}/pkey.pem"
      set :port, @config[:http_port]
      set :bind, "0.0.0.0"

      @@SEND_DATA_TIMEOUT = 5.seconds
      @@CONTROLLER_PORT = 52161


      post '/request', :provides => [ 'html', 'json' ] do
        data = JSON.parse request.body.read
        translate_request(data)
      end

      # {
      # "Userid" : "Recon1",
      #   "RequestType": "surveillance/surveillance",
      #   "Service": "count objects",
      #   "CameraGPSLatitude" : "44.12121",
      #   "CameraGPSLongitude" : "12.21212",
      #   "CameraUrl": "http://weathercam.digitraffic.fi/C0150200.jpg"
      # }

      # REQUEST participants/find_text
      # User 3;44.838124,11.619786;find "water"
      #
      # OR
      #
      # REQUEST surveillance/surveillance
      # User 3;44.838124,11.619786;face_detection;https://example.info/camId.jpg
      def translate_request(data)
        if data.nil?
          return
        end
        logger.info "*** Received request: #{data} ***"
        Thread.new do
          socket = nil
          begin
            status = Timeout::timeout(@@SEND_DATA_TIMEOUT) do
              socket = TCPSocket.open("127.0.0.1", @@CONTROLLER_PORT)
              logger.debug ("REQUEST #{data['RequestType']} ")
              socket.puts("REQUEST #{data['RequestType']} ")
              socket.puts("User #{data['Userid']};#{data['CameraGPSLatitude']},#{data['CameraGPSLongitude']};#{data['Service']};#{data['CameraUrl']}")
              logger.debug("User #{data['Userid']};#{data['CameraGPSLatitude']},#{data['CameraGPSLongitude']};#{data['Service']};#{data['CameraUrl']}")
              logger.info "*** #{self.class.name}: Send request to controller for user #{data['Userid']} ***"
            end
          rescue Timeout::Error => e
            logger.warn "*** #{self.class.name}: Failed send request to controller for user #{data['Userid']}, timeout error ***"
          rescue => e
            logger.warn "*** #{self.class.name}: Exception #{e} ***"
            logger.warn "*** #{self.class.name}: Failed send request to controller for user #{data['Userid']}, controller is unreachable ***"
          ensure
            unless socket.nil?
              socket.close
            end
          end
        end

        logger.info "*** Finished translate_request for: #{data} ***"
      end
    end
  end
end
