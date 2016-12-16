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

      def initialize(service_manager, filename)
        @filename = filename
        @service_manager = service_manager
        @applications = {}
        # NOTE: added disservice instance needed by Application.new
        @disservice_handler = DisServiceHandler.new
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
        #NOTE: i can write 'application.config' because there is 'attr_reader :config' in Application class
        @applications.delete_if { |application| SPF::Common::Validate.conf? application.config }
      end

      def reprogram(text)
        instance_eval(text)
      end

      def self.load_from_file(service_manager, filename)
        # allow filename, string, and IO objects as input
        raise ArgumentError, "File #{filename} does not exist!" unless File.exist?(filename)

        # Dir.glob(File.join(CONFIG_FOLDER, filename)) do |conf|
        File.open(filename) do |conf|

          # create configuration object
          conf = PIGConfiguration.new(service_manager, filename)

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
