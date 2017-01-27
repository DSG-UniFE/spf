require 'spf/common/validate'
require 'spf/common/logger'

require_relative './application'
require_relative './disservice_handler'


module SPF
  module Gateway

    class PIGConfiguration

      include SPF::Logging

      attr_reader :applications
      attr_reader :cameras
      attr_reader :location
      attr_reader :alias_name
      attr_reader :controller_address
      attr_reader :controller_port
      CONFIG_FOLDER = File.join('etc', 'gateway')

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
          conf.validate

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
          conf.validate

          # return new object
          conf.cameras
        end
      end

      #NOTE : Verify application validation
      def validate
          @applications.delete_if { |app_name, app| !SPF::Common::Validate.conf? app.config }
          #TODO: fare la validate delle cameras
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
          @service_manager = service_manager
          @disservice_handler = disservice_handler
          @cameras = []
        end
  
        def application(name, options)
          @applications[name.to_sym] =
            Application.new(name, options, @service_manager, @disservice_handler)
          logger.info "*** Pig: Added new application: #{name}"
        end
  
        def configuration(conf)
          @alias_name = conf[:alias_name]
          @location[:gps_lat] = conf[:gps_lat]
          @location[:gps_lon] = conf[:gps_lon]
          @controller_address = conf[:controller_address]
          @controller_port = conf[:controller_port]
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
