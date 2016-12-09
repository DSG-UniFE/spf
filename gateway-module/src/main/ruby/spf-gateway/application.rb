module SPF
  module Gateway
    class Application
      
      DEFAULT_RESPONSE_EXPIRATION_TIME = 2 * 60 * 1000    # 2 minutes

      attr_reader :name
      attr_reader :priority
      
      # NOTE: added 'config' in order to be readable from external
      attr_reader :config

      # Create application.
      #
      # @param name [String] The application name.
      # @param config [Hash] The application configuration.
      # @param service_manager [SPF::Gateway::ServiceManager] The PIG ServiceManager instance.
      # @param disservice_handler [SPF::Gateway::DisServiceHandler] The DisServiceHandler instance.
      def initialize(name, config, service_manager, disservice_handler)
        @config = config
        @name = name.to_sym
        @priority = config[:priority]
        @response_expiration_time = DEFAULT_RESPONSE_EXPIRATION_TIME
        @disservice_handler = disservice_handler

        @services = Hash[
          config[:service_policies].map do |service_name, service_conf|
            [ service_name.to_sym, service_manager.instantiate_service(service_name.to_sym, service_conf, self) ]
          end
        ]
      end

      #NOTE : could we use def_delegator for below methods to save code?

      def add_service_policy(service_name, service_conf)
        @services[service_name].add_service_policy(service_conf)
      end

      def add_dissemination_policy(service_name, service_conf)
        @services[service_name].add_dissemination_policy(service_conf)
      end

      def change_service_policy(service_name, service_conf)
        @services[service_name].change_service_policy(service_conf)
      end

      def change_dissemination_policy(service_name, service_conf)
        @services[service_name].change_dissemination_policy(service_conf)
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
