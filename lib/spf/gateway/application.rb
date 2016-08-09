module SPF
  module Gateway
    class Application

      attr_reader :priority

      # Create application.
      #
      # @param config [Hash] The application configuration.
      # @param service_manager [SPF::Gateway::ServiceManager] The PIG ServiceManager instance.
      def initialize(config, service_manager)
        @priority = config[:priority]

        # @services = Hash[
        #   config[:service_policies].map do |service_name,service_conf|
        #     [ service_name, Service.new(service_name, service_conf, service_registry) ]
        #   end
        # ]

        @services = {}
        config[:service_policies].each do |service_name,service_conf|
          @services[service_name] = Service.new(service_name, service_conf, self, service_manager)
        end
      end

      # Disseminate the processed results.
      def disseminate
        # TODO: implement
      end

    end
  end
end
