require 'spf/common/logger'


module SPF
  module Gateway

    class MqttDisseminationHandler

      include SPF::Logging

      # Mqtt broker address and port
      MQTT_DEFAULT_HOST = '127.0.0.1'
      MQTT_DEFAULT_PORT = 1833

      def initialize(address = MQTT_DEFAULT_HOST, port = MQTT_DEFAULT_PORT)
        @mqtt_client = MQTT::Client.new
        @mqtt_client.host = address
        @mqtt_client.port = port.to_i
        @keep_going = Concurrent::AtomicBoolean.new(true)
        begin
            @mqtt_client.connect
            logger.info "*** #{self.class.name}: Connected to MQTT broker ***"
        rescue
            logger.error "*** #{self.class.name}: MQTT client error, Connection failed ***"
            @keep_going.make_false
            exit
        end
      end

      def push_to_broker(group_name, io, qos = 0)
        # do we need to stop the broker in case of error?
        begin
            @mqtt_client.publish(group_name, io, qos)
        rescue
            logger.error "*** #{self.class.name}: MQTT client error, Connection failed ***"
            @keep_going.make_false
            exit
        end
        logger.info "*** #{self.class.name}: pushed an IO of #{io.bytesize} bytes to DisService ***"
      end

    end
  end
end
