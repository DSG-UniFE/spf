require 'spf/gateway/controller'

module SPF
  class Gateway
    DEFAULT_IOT_PORT = 2160
    DEFAULT_PROGRAMMING_PORT = 52160

    def initialize(host,
                   iot_address = 'localhost',
                   iot_port = DEFAULT_IOT_PORT,
                   programming_address = 'localhost',
                   programming_port = DEFAULT_PROGRAMMING_PORT)
      @iot_address         = iot_address
      @iot_port            = iot_port
      @programming_address = programming_address
      @programming_port    = programming_port
    end

    def run
      Thread.new { SPF::Gateway::Processor.new(@iot_address, @iot_port).run }
      Thread.new { SPF::Gateway::Controller.new(@programming_address, @programming_port).run }
    end
  end
end
