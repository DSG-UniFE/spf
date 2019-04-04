require 'concurrent'
require 'mqtt'


require 'spf/common/logger'
require 'spf/gateway/sensor_receiver'
require 'spf/common/tcpserver_strategy'
require 'spf/common/extensions/thread_reporter'


# disable useless DNS reverse lookup
BasicSocket.do_not_reverse_lookup = true

module SPF
  module Gateway
    class MqttDataListener

      include SPF::Logging

      # Mqtt broker address and port
      MQTT_DEFAULT_HOST = '127.0.0.1'
      MQTT_DEFAULT_PORT = 1833
      # subscribe to one or multiple topics
      DEFAULT_TOPICS = ["sensor_data"]

      def initialize(data_queue, host=MQTT_DEFAULT_HOST,
                      port=MQTT_DEFAULT_PORT, topics=DEFAULT_TOPICS)
        @mqtt_client = MQTT::Client.new
        @mqtt_client.host = MQTT_DEFAULT_HOST
        @mqtt_client.port = MQTT_DEFAULT_PORT.to_i
        @topics = DEFAULT_TOPICS
        @keep_going = Concurrent::AtomicBoolean.new(true)
        @threads = Array.new
        @data_queue = data_queue
      end

      def run(opts = {})
        begin
        @mqtt_client.connect()
        rescue
          logger.error "*** #{self.class.name}: MQTT client error, Connection failed ***"
          @keep_going.make_false
          abort
        end

        begin
        # subscribe to specificed topics
        @topics.each do |t|
          logger.debug "*** #{self.class.name} Subscribing to #{t} ***"
           @mqtt_client.subscribe(t) 
        end

        # then loop for incoming messages
        @mqtt_client.get do |topic, message|
          logger.info "*** #{self.class.name} Received message regarding topic: #{topic} ***"
        end
        rescue
          logger.warn "*** #{self.class.name}: MQTT client error ***"
        end

      end

      private

        def shutdown
          @mqtt_client.close
          @keep_going.make_false
        end

    end
  end
end
