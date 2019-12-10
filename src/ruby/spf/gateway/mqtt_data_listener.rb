require 'java'
require "concurrent"
require "mqtt"

require "spf/common/logger"
require "spf/gateway/sensor_receiver"
require "spf/common/tcpserver_strategy"
require "spf/common/extensions/thread_reporter"
require "spf/gateway/broker"

# disable useless DNS reverse lookup
BasicSocket.do_not_reverse_lookup = true

module SPF
  module Gateway
    class MqttDataListener
      include SPF::Logging

      def initialize(conf, data_queue)
        @broker_repository = Hash[
        conf.brokers.map do |b_id, b_conf|
          address = b_conf[:address]
          port = b_conf[:port]
          topics = b_conf[:topics]
          [b_id, Broker.new(address, port, topics)]
        end
        ]
        # init the list of mqtt clients
        mqtt_clients = []

        @broker_repository.each do |_, b|
          Thread.new { MqttBrokerHandler.new(b, data_queue).run }
          #mqtt_clients << client
          #client.run
        end
      end

    end

    # handle the connection with the broker
    class MqttBrokerHandler
      include SPF::Logging

      # Mqtt broker address and port
      MQTT_DEFAULT_HOST = "127.0.0.1"
      MQTT_DEFAULT_PORT = 1883
      # subscribe to one or multiple topics
      DEFAULT_TOPICS = ["sensors"]
      
      def initialize(broker, data_queue)
        @broker = broker
        @data_queue = data_queue
        @mqtt_client = nil
      end

      # one thread per MQTT Connection
      def run(opts = {})
        # init thread
        @mqtt_client = MQTT::Client.new
        @mqtt_client.host = @broker.address
        @mqtt_client.port = @broker.port.to_i
        @topics = @broker.topics
        @keep_going = Concurrent::AtomicBoolean.new(true)
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
          logger.debug "*** #{self.class.name} Received message #{message} of size #{message.length} on topic: #{topic} ***"
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
