require "concurrent"
require "mqtt"

require "spf/common/logger"
require "spf/gateway/sensor_receiver"
require "spf/common/tcpserver_strategy"
require "spf/common/extensions/thread_reporter"

# disable useless DNS reverse lookup
BasicSocket.do_not_reverse_lookup = true

module SPF
  module Gateway
    class MqttDataListener
      include SPF::Logging

      # Mqtt broker address and port
      MQTT_DEFAULT_HOST = "127.0.0.1"
      MQTT_DEFAULT_PORT = 1883
      # subscribe to one or multiple topics
      DEFAULT_TOPICS = ["sensors"]

      def initialize(data_queue, host = MQTT_DEFAULT_HOST,
                                 port = MQTT_DEFAULT_PORT, topics = DEFAULT_TOPICS)
        @mqtt_client = MQTT::Client.new
        @mqtt_client.host = MQTT_DEFAULT_HOST.to_s
        @mqtt_client.port = MQTT_DEFAULT_PORT.to_i
        @topics = DEFAULT_TOPICS
        @keep_going = Concurrent::AtomicBoolean.new(true)
        @data_queue = data_queue
      end

      def run(opts = {})
        begin
          @mqtt_client.connect()
        rescue
          logger.error "*** #{self.class.name}: MQTT client error, Connection failed ***"
          @keep_going.make_false
          exit
        end

        logger.info "*** #{self.class.name} Connected to MQTT broker ***"

        # subscribe to specificed topics
        @topics.each do |t|
          logger.debug "*** #{self.class.name} Subscribing to #{t} ***"
          @mqtt_client.subscribe(t)
        end

        logger.info "*** #{self.class.name} Subscribed to #{@topics} ***"

        # then loop for incoming messages
        @mqtt_client.get do |topic, message|
          logger.info "*** #{self.class.name} Received message #{message} on topic: #{topic} ***"
          # then push data into the queue
          @data_queue.push(message, 1, nil)
          logger.debug "*** #{self.class.name}: Pushed data from MQTTListener into the queue ***"
        end

        logger.info "*** #{self.class.name} After incoming message loop ***"
      end

      private

      def shutdown
        @mqtt_client.close
        @keep_going.make_false
      end
    end
  end
end
