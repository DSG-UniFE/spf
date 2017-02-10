require 'concurrent'

require 'spf/common/logger'
require 'spf/gateway/configuration'
require 'spf/gateway/data_listener'
require 'spf/gateway/data_requestor'
require 'spf/gateway/service_manager'
require 'spf/gateway/disservice_handler'
require 'spf/gateway/configuration_agent'


module SPF
  module Gateway
    class PIG

    include SPF::Logging

      @@LOCATION = {}

      def initialize()
        begin
          camera_path = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'etc', 'gateway', 'ip_cameras'))
          config_path = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'etc', 'gateway', 'pig_configuration'))

          # Retrieve instances of Service Manager and DisService Handler
          @service_manager = SPF::Gateway::ServiceManager.new
          @disservice_handler = SPF::Gateway::DisServiceHandler.new

          # Read Pig Configuration (now only the location - gps coordinates)
          @config = SPF::Gateway::PIGConfiguration.load_from_file(config_path, @service_manager, @disservice_handler)
          @cameras_config = SPF::Gateway::PIGConfiguration.load_cameras_from_file(camera_path, @service_manager, @disservice_handler)
        rescue ArgumentError => e
          logger.error "*** #{self.class.name}: #{e.message} ***"
          exit
        rescue SPF::Common::Exceptions::ConfigurationError => e
          logger.error "#{e.message}"
          exit
        end
        @@LOCATION[:lat] = @config.location[:lat]
        @@LOCATION[:lon] = @config.location[:lon]
      end

      def self.location
        @@LOCATION
      end

      def run
        Thread.new { SPF::Gateway::DataListener.new(@service_manager).run }
        # Thread.new { SPF::Gateway::DataRequestor.new(@cameras_config, @service_manager).run }

        SPF::Gateway::ConfigurationAgent.new(@service_manager, @config,
                                              @config.controller_address,
                                              @config.controller_port).run
      end

    end
  end
end
