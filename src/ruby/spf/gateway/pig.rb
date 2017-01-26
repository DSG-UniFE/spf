require 'concurrent'

require 'spf/gateway/data_listener'
require 'spf/gateway/configuration_agent'
require 'spf/gateway/data_requestor'


module SPF
  module Gateway
    class PIG
      
      def_delegator :@config, :location

      DEFAULT_IOT_PORT = 2160
      DEFAULT_CONTROLLER_PORT = 52160

      def initialize(configuration, cameras, service_manager, disservice_handler,
                     controller_address='127.0.0.1', controller_port=DEFAULT_CONTROLLER_PORT,
                     iot_address='0.0.0.0', iot_port=DEFAULT_IOT_PORT)

        @cams                 = cameras
        @config               = configuration
        @service_manager      = service_manager
        @disservice_handler   = disservice_handler
        @controller_address   = controller_address
        @controller_port      = controller_port
        @iot_address          = iot_address
        @iot_port             = iot_port
        @request_hash         = Concurrent::Hash.new
      end

      def run
        #Thread.new { SPF::Gateway::DataListener.new(@iot_address, @iot_port, @service_manager, @request_hash).run }
        Thread.new { SPF::Gateway::DataRequestor.new(@cams, @service_manager, @request_hash).run }

        SPF::Gateway::ConfigurationAgent.new(@service_manager, @controller_address, @controller_port, @config, @request_hash).run
      end

    end
  end
end
