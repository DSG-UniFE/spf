require 'forwardable'

require 'spf-gateway/controller'

module SPF
  module Gateway
    class PIG
      DEFAULT_IOT_PORT = 2160
      DEFAULT_PROGRAMMING_PORT = 52160

      # delegate location to @config
      extend Forwardable
      def_delegator :@config, :location

      def initialize(configuration,      # PIGConfiguration::load_from_file(conf_filename)
                     service_manager,    # ServiceManager.instance
                     disservice_handler, # DisServiceHandler.new
                     iot_address = 'localhost',
                     iot_port = DEFAULT_IOT_PORT,
                     programming_address = 'localhost',
                     programming_port = DEFAULT_PROGRAMMING_PORT)
        @config              = configuration
        @service_manager     = service_manager
        @disservice_handler  = disservice_handler
        @iot_address         = iot_address
        @iot_port            = iot_port
        @programming_address = programming_address
        @programming_port    = programming_port
      end

      def run
        Thread.new { SPF::Gateway::DataListener.new(@iot_address, @iot_port, @service_manager).run }
        Thread.new { SPF::Gateway::ConfigurationAgent.new(@programming_address, @programming_port).run }
      end
    end
  end
end
