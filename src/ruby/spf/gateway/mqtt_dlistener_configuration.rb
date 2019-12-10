require 'concurrent'

require 'spf/common/logger'
require 'spf/common/validate'
require 'spf/common/exceptions'

require_relative './application'
require_relative './disservice_handler'
require_relative './dspro_handler'


module SPF
  module Gateway

    class MqttDlistenerConfiguration

      include SPF::Logging

      attr_reader :topics, :brokers 

      def self.load_from_file(filename)
        # allow filename, string, and IO objects as input
        raise ArgumentError, "#{self.class.name}: File #{filename} does not exist!" unless File.exist?(filename)

        File.open(filename) do |conf|

          # create configuration object
          conf =  MqttDlistenerConfiguration.new(filename)

          # take the file content and pass it to instance_eval
          conf.instance_eval(File.new(filename, 'r').read)

          # validate and finalize configuration
          # conf.validate
          raise SPF::Common::Exceptions::ConfigurationError, "*** #{self.class.name}: MQTT DataListner configuration '#{filename}' not passed validate! ***" unless conf.validate_mqtt_dlistner_conf?

          # return new object
          conf
        end
      end

      def validate_mqtt_dlistner_conf?
        return SPF::Common::Validate.pig_config?(@alias_name, @location, \
                                                  @controller_address,
                                                  @controller_port, @tau_test,
                                                  @min_thread_size,
                                                  @max_thread_size,
                                                  @max_queue_thread_size,
                                                  @queue_size)
      end


      def reprogram(text)
        instance_eval(text)
      end


      private

        def initialize(filename)
          @filename = filename
          @topics = {}
          @brokers = {}
        end

        def application(name, options)
          @applications[name.to_sym] =
            Application.new(name, options, @service_manager, @disseminaton_handler)
          logger.info "*** #{self.class.name}: Added new application - #{name}"
        end

        def configuration(conf)
          @alias_name = conf[:alias_name]
          @location[:lat] = conf[:lat]
          @location[:lon] = conf[:lon]
          @controller_address = conf[:controller_address]
          @controller_port = conf[:controller_port]
          @min_thread_size = conf[:min_thread_size]
          @max_thread_size = conf[:max_thread_size]
          @max_queue_thread_size = conf[:max_queue_thread_size]
          @queue_size = conf[:queue_size]
          @tau_test = conf[:tau_test]
          @mqtt_topics = conf[:mqtt_topics]
        end

        def ip_cameras(cams)
          @cameras = cams
        end

        def modify_application(name, options)
          name = name.to_sym
          return unless @applications.has_key?(name)

          options.each do |k,v|
            case k.to_s
            when :add_services
              v.each do |service_name,service_conf|
                @applications[name].instantiate_service(service_name, service_conf)
              end
            when :update_service_configurations
              v.each do |service_name,service_conf|
                @applications[name].update_service_configuration(service_name, service_conf)
              end
            end
          end
        end
    end

    # class DisseminationConfiguration
    # Load the dissemination configuration from file
    # Currently supported dissemination types are DisService, DSPro
    # Use MQTT also as dissemination interface
    class DisseminationConfiguration
      include SPF::Logging

      attr_reader :dissemination_type, :disseminator_address,
        :disseminator_port, :dspro_path, :dspro_config_path, :disservice_path,
        :disservice_config_path

      def initialize(filename)
        @filename = filename
        @dissemination_type = ""
        @disseminator_address = "127.0.0.1"
        @disseminator_port = 56487
        @dspro_path = ""
        @dspro_config_path = ""
        @disservice_path = ""
        @disservice_config_path = ""
        @mqtt_broker_address = "127.0.0.1"
        @mqtt_broker_port = 1833
      end

      # do we need to strip?
      def configuration(conf)
        @dissemination_type = conf[:dissemination_type].strip
        @disseminator_address = conf[:disseminator_address].nil? ? nil : conf[:disseminator_address].strip
        @disseminator_port = conf[:disseminator_port].nil? ? nil : conf[:disseminator_port].strip
        @dspro_path = conf[:dspro_path].nil? ? nil : conf[:dspro_path].strip
        @dspro_config_path = conf[:dspro_config_path].nil? ? nil : conf[:dspro_config_path].strip
        @disservice_path = conf[:disservice_path].nil? ? nil : conf[:disservice_path].strip
        @disservice_config_path = conf[:disservice_config_path].nil? ? nil : conf[:disservice_config_path].strip
        @mqtt_broker_address = conf[:mqtt_broker_address]
        @mqtt_broker_port = conf[:mqtt_broker_port]
      end

      def self.load_from_file(filename)
        # allow filename, string, and IO objects as input
        raise ArgumentError, "#{self.class.name}: File #{filename} does not exist!" unless File.exist?(filename)

        File.open(filename) do |conf|

          # create configuration object
          conf = DisseminationConfiguration.new(filename)

          # take the file content and pass it to instance_eval
          conf.instance_eval(File.new(filename, 'r').read)

          # validate and finalize configuration
          raise SPF::Common::Exceptions::ConfigurationError, "*** #{self.class.name}: Dissemination configuration '#{filename}' not passed validate! ***" unless conf.validate_dissemination_config?

          conf
        end
      end

      # Validate the dissemintion config
      def validate_dissemination_config?
        return SPF::Common::Validate.dissemination_config?(@dissemination_type, @disseminator_address, @disseminator_port,
                               @dspro_path, @dspro_config_path, @disservice_path, @disservice_config_path, @mqtt_broker_address,
                               @mqtt_broker_port)
      end

    end
  end
end
