require 'forwardable'
require_relative './gps'

module SPF
  module Gateway
    class Service

      # Dissemination is handled at the application level.
      extend Forwardable
      def_delegator :@application, :disseminate

      attr_reader :name, :tau

      # Create service.
      #
      # @param name [Symbol] The service name.
      # @param configuration [Hash] The service configuration.
      # @param application [SPF::Gateway::Application] The application this service refers to.
      # @param service_strategy [SPF::Gateway::Service_Strategy] An object that implements the
      #                                                          Service_Strategy interface.
      # @param service_manager [SPF::Gateway::ServiceManager] The PIG ServiceManager instance.
      def initialize(name, service_conf, application, 
                     service_strategy, service_manager)
        @name = name
        @tau = service_conf[:tau]
        @max_idle_time = service_conf[:uninstall_after]
        @service_strategy = service_strategy
        @application = application
        @service_manager = service_manager
      end

      # 001;11.48,45.32;find "water"\n
      # 002;11.48,45.32;find "food"\n
      def register_request(socket)
        while line = socket.gets do
          req_id, req_loc, req_string = line.split(";")
          @service_strategy.add_request(req_id, req_loc, req_string)
        end
      end

      def new_information(io, source)
        # get response from service strategy
        response, voi =
          @service_strategy.execute_service(io, source)

        # disseminate calls DisService
        @application.disseminate(response, voi)
      end

    end
  end
end
