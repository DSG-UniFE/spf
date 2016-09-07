require 'spf/gateway/controller'

module SPF
  class PIG
    DEFAULT_IOT_PORT = 2160
    DEFAULT_PROGRAMMING_PORT = 52160

    attr_reader :location

    def initialize(host,
                   conf_filename,
                   iot_address = 'localhost',
                   iot_port = DEFAULT_IOT_PORT,
                   programming_address = 'localhost',
                   programming_port = DEFAULT_PROGRAMMING_PORT)
      config = PIGConfiguration::load_from_file(conf_filename) 
      @iot_address         = iot_address
      @iot_port            = iot_port
      @programming_address = programming_address
      @programming_port    = programming_port
      @location            = config[:location]
      @service_manager     = ServiceManager.instance
      @disservice_handler  = DisServiceHandler.new
    end

    def run
      Thread.new { SPF::Gateway::DataListener.new(@iot_address, @iot_port, @service_manager).run }
      Thread.new { SPF::Gateway::ConfigurationAgent.new(@programming_address, @programming_port).run }
    end
  end
end
