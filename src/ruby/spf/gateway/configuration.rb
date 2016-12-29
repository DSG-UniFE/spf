require 'spf/common/validate'

require_relative './application'
require_relative './disservice_handler'


module SPF
  module Gateway

    class PIGConfiguration

      attr_reader :applications

      CONFIG_FOLDER = File.join('etc', 'gateway')

      ############################################################
      # TODO: make the following methods private
      ############################################################

      def initialize(filename, service_manager, disservice_handler)
        @filename = filename
        @applications = {}
        @location = {}
        @service_manager = service_manager
        @disservice_handler = disservice_handler
      end

      def application(name, options)
        @applications[name.to_sym] =
          Application.new(name, options, @service_manager, @disservice_handler)
      end

      def location(loc)
        @location = loc
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

      ############################################################
      # TODO: make the methods above private
      ############################################################

      #NOTE : Verify application validation
      def validate
        @applications.delete_if { |app_name, app| !SPF::Common::Validate.conf? app.config }
      end

      def reprogram(text)
        instance_eval(text)
      end

      def self.load_from_file(filename, service_manager, disservice_handler)
        # allow filename, string, and IO objects as input
        raise ArgumentError, "Pig: File #{filename} does not exist!" unless File.exist?(filename)

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

    end
  end
end
