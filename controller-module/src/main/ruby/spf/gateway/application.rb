module SPF
  module Gateway
    class Application

      attr_reader :name
      attr_reader :priority

      # Create application.
      #
      # @param name [String] The application name.
      # @param config [Hash] The application configuration.
      # @param service_manager [SPF::Gateway::ServiceManager] The PIG ServiceManager instance.
      def initialize(name, config, service_manager)
        @name = name.to_sym
        @priority = config[:priority]

        @services = Hash[
          config[:service_policies].map do |service_name,service_conf|
            [ service_name.to_sym, service_manager.instantiate_service(service_name.to_sym, service_conf, self) ]
          end
        ]
      end

      # Disseminate the processed results.
      #
      # @param io [Array] The IO to disseminate.
      # @param voi [Float] VoI parameter (between 0.0 and 100.0) for the IO to disseminate.
      def disseminate(io, voi)
        # TODO: implement
      end

    end
  end
end
