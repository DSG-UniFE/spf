require 'concurrent'
require 'sinatra/base'

require 'spf/common/logger'
require 'spf/common/exceptions'
require 'spf/common/extensions/fixnum'

require_relative './configuration'
require_relative './json_handler'
#require_relative './sinatra_ssl'

module SPF
  module Controller
    class HttpInterface < Sinatra::Base

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
        JsonHandler.translate_request(data)
      end
    end
  end
end
