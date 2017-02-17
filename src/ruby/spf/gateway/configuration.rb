require 'spf/common/logger'
require 'spf/common/validate'
require 'spf/common/exceptions'

require_relative './application'
require_relative './disservice_handler'


module SPF
  module Gateway

    class PIGConfiguration

      include SPF::Logging

      attr_reader :applications, :cameras, :location, :alias_name, :controller_address, :controller_port, :tau_test

      def self.load_from_file(filename, service_manager, disservice_handler)
        # allow filename, string, and IO objects as input
        raise ArgumentError, "#{self.class.name}: File #{filename} does not exist!" unless File.exist?(filename)

        # Dir.glob(File.join(CONFIG_FOLDER, filename)) do |conf|
        File.open(filename) do |conf|

          # create configuration object
          conf = PIGConfiguration.new(filename, service_manager, disservice_handler)

          # take the file content and pass it to instance_eval
          conf.instance_eval(File.new(filename, 'r').read)

          # validate and finalize configuration
          # conf.validate
          raise SPF::Common::Exceptions::ConfigurationError, "*** #{self.class.name}: PIG configuration '#{filename}' not passed validate! ***" unless conf.validate_pig_config?

          # return new object
          conf
        end
      end

      def self.load_cameras_from_file(filename, service_manager, disservice_handler)
        # allow filename, string, and IO objects as input
        raise ArgumentError, "#{self.class.name}: File #{filename} does not exist!" unless File.exist?(filename)

        # Dir.glob(File.join(CONFIG_FOLDER, filename)) do |conf|
        File.open(filename) do |conf|

          # create configuration object
          conf = PIGConfiguration.new(filename, service_manager, disservice_handler)

          # take the file content and pass it to instance_eval
          conf.instance_eval(File.new(filename, 'r').read)

          # validate and finalize configuration
          raise SPF::Common::Exceptions::ConfigurationError, "*** #{self.class.name}: Camera configuration '#{filename}' not passed validate! ***" unless conf.validate_camera?

          # return new object
          conf.cameras
        end
      end

      def validate_camera?
        @cameras.each do |camera|
          return false unless SPF::Common::Validate.camera_config? camera
        end
        return true
      end

      def validate_pig_config?
        return SPF::Common::Validate.pig_config?(@alias_name, @location, \
                                                  @controller_address,
                                                  @controller_port,
                                                  @tau_test)
      end

      def validate_app_config?
          return SPF::Common::Validate.app_config? app.config
      end

      def reprogram(text)
        instance_eval(text)
      end


      private

        def initialize(filename, service_manager, disservice_handler)
          @filename = filename
          @applications = {}
          @location = {}
          @alias_name = ""
          @controller_address = ""
          @controller_port = ""
          @tau_test = false
          @service_manager = service_manager
          @disservice_handler = disservice_handler
          @cameras = []
        end

        def application(name, options)
          @applications[name.to_sym] =
            Application.new(name, options, @service_manager, @disservice_handler)
          logger.info "*** #{self.class.name}: Added new application - #{name}"
        end

        def configuration(conf)
          @alias_name = conf[:alias_name]
          @location[:lat] = conf[:lat]
          @location[:lon] = conf[:lon]
          @controller_address = conf[:controller_address]
          @controller_port = conf[:controller_port]
          @tau_test = conf[:tau_test]
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
  end
end
