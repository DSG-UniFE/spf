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
      # @param name [String] The service name.
      # @param configuration [Hash] The service configuration.
      # @param application [SPF::Gateway::Application] The application this service refers to.
      # @param service_strategy_class [Constant] The class of the service strategy to use.
      # @param service_manager [SPF::Gateway::ServiceManager] The PIG ServiceManager instance.
      def initialize(name, configuration, application, 
                     service_strategy_class, service_manager)
        @name = name.to_sym
        @tau = configuration[:tau]
        # TODO: should we use a factory here instead?
        @service_strategy = service_strategy_class.new(
          configuration[:time_decay],
          configuration[:distance_decay])
        @application = application
        @service_manager = service_manager
      end

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
        @app.disseminate(response, voi)
      end

    end
  end
end
