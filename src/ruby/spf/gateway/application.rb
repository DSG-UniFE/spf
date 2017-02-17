require 'spf/common/logger'


module SPF
  module Gateway
    class Application

      include SPF::Logging

      attr_reader :name, :priority, :config

      # Create application.
      #
      # @param name [String] The application name.
      # @param config [Hash] The application configuration.
      # @param service_manager [SPF::Gateway::ServiceManager] The PIG ServiceManager instance.
      # @param disservice_handler [SPF::Gateway::DisServiceHandler] The DisServiceHandler instance.
      def initialize(name, config, service_manager, disservice_handler)
        @name = name
        @config = config
        @priority = config[:priority] / 100
        @service_manager = service_manager
        @disservice_handler = disservice_handler
        # @disservice_handler.subscribe(@name.to_s)
        @services = {}

        config[:service_policies].map do |service_name, service_conf|
          # create_service(service_name, service_conf)
          instantiate_service(service_name, service_conf)
        end
      end

      # Instantiate service.
      #
      # This method is not designed to be called directly, but to be called
      # from the constructor and from {SPF::Gateway::PIGConfiguration} upon a
      # REPROGRAM request.
      def instantiate_service(service_name, service_conf)
        @services[service_name.to_sym] =
          @service_manager.instantiate_service(service_name.to_sym, service_conf, self)
      end

      # Update the configuration of a service.
      #
      # This method is not designed to be called directly, but to be called
      # from {SPF::Gateway::PIGConfiguration} upon a REPROGRAM request.
      def update_service_configuration(service_name, service_conf)
        @services[service_name].update_configuration(service_conf)
      end

      # Disseminate the processed results.
      #
      # @param object_str [String] The objectID of the IO to disseminate.
      # @param instance_str [String] The instanceID of the IO to disseminate.
      # @param mime_type [String] The MIME type of the IO to disseminate.
      # @param io [Array] The IO to disseminate.
      # @param voi [Float] VoI parameter (between 0.0 and 100.0) for the IO to disseminate.
      # @param expiration_time [int] Time (in milliseconds) after which the IO expires.
      def disseminate(object_str, instance_str, mime_type, io, voi, expiration_time)
        @disservice_handler.push_to_disservice(@name.to_s, object_str, instance_str,
                                               mime_type, io, voi, expiration_time)
      end

    end
  end
end
