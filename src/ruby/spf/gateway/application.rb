module SPF
  module Gateway
    class Application

      @@DEFAULT_RESPONSE_EXPIRATION_TIME = 2 * 60 * 1000 # 2 minutes

      attr_reader :name
      attr_reader :priority
      attr_reader :config

      # Create application.
      #
      # @param name [String] The application name.
      # @param config [Hash] The application configuration.
      # @param service_manager [SPF::Gateway::ServiceManager] The PIG ServiceManager instance.
      # @param disservice_handler [SPF::Gateway::DisServiceHandler] The DisServiceHandler instance.
      def initialize(name, config, service_manager, disservice_handler)
        @name = name
        @config = config
        @priority = config[:priority]
        @response_expiration_time = @@DEFAULT_RESPONSE_EXPIRATION_TIME
        @service_manager = service_manager
        @disservice_handler = disservice_handler
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
      # @param io [Array] The IO to disseminate.
      # @param voi [Float] VoI parameter (between 0.0 and 100.0) for the IO to disseminate.
      def disseminate(mime_type, io, voi)
        @disservice_handler.push_to_disservice(@name.to_s, "", "", mime_type, io, voi, response_expiration_time)
      end

    end
  end
end
