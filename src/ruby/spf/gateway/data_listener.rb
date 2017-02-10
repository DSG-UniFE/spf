require 'socket'
require 'concurrent'
require 'spf/common/logger'
require 'spf/gateway/sensor_receiver'
require 'spf/common/tcpserver_strategy'

module SPF
  module Gateway
    class DataListener < SPF::Common::TCPServerStrategy

      include SPF::Logging

      DEFAULT_HOST = '0.0.0.0'
      DEFAULT_PORT = 2160

      def initialize(service_manager, host=DEFAULT_HOST, port=DEFAULT_PORT)
        super(host, port, self.class.name)
        @service_manager = service_manager
        @pool = Concurrent::CachedThreadPool.new
      end

      private

        def handle_connection(sensor_socket)

          Thread.new {SPF::Gateway::SensorReceiver.new(@pool, @service_manager, sensor_socket).run}
          
        end

    end
  end
end
