require "concurrent"

require "spf/common/logger"
require "spf/common/validate"
require "spf/common/exceptions"
require "spf/common/dsl_helper"

module SPF
  module Gateway

    module Configurable
      dsl_accessor :brokers,
                   :alpha
    end

    class MqttDlistenerConfiguration
      include SPF::Logging
      include Configurable

      def self.load_from_file(filename)
        # allow filename, string, and IO objects as input
        puts "Loading configuration from file"
        raise ArgumentError, "#{self.class.name}: File #{filename} does not exist!" unless File.exist?(filename)

        File.open(filename) do |conf|

          # create configuration object
          conf = MqttDlistenerConfiguration.new(filename)
          # take the file content and pass it to instance_eval

          conf.instance_eval(File.new(filename, "r").read)
          # validate and finalize configuration
          # conf.validate
          raise SPF::Common::Exceptions::ConfigurationError, "*** #{self.class.name}: MQTT DataListner configuration '#{filename}' not passed validate! ***" unless conf.validate_mqtt_dlistner_conf?

          # return new configuration object
          conf
        end
      end

      def validate_mqtt_dlistner_conf?
        return SPF::Common::Validate.mqtt_dlistener_conf?(@brokers)
      end

      def configuration(conf)
        puts "Configuration being loaded: #{conf}"
        #@brokers = conf[:brokers]
      end

      private
        def initialize(filename)
          @filename = filename
        end
    end
  end
end
