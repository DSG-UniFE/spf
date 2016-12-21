require 'forwardable'
require 'concurrent'
require_relative './gps'

module SPF
  module Gateway
    class Service

      # Dissemination is handled at the application level.
      extend Forwardable
      def_delegator :@application, :disseminate

      attr_reader :name, :tau, :max_idle_time, :pipeline_name, :application

      # Create service.
      #
      # @param name [Symbol] The service name.
      # @param configuration [Hash] The service configuration.
      # @param application [SPF::Gateway::Application] The application this service refers to.
      # @param service_strategy [SPF::Gateway::Service_Strategy] An object that implements the
      #                                                          Service_Strategy interface.
      def initialize(name, service_conf, application, service_strategy)
        @name = name
        @tau = service_conf[:tau]
        @max_idle_time = service_conf[:uninstall_after]
        @pipeline_name = service_conf[:processing_pipeline].to_sym
        @service_strategy = service_strategy
        @application = application
        @is_active = false
        @is_active_lock = Concurrent::ReadWriteLock.new
      end

      # 001;11.48,45.32;find "water"\n
      # 002;11.48,45.32;find "food"\n
      def register_request(socket)
        @is_active_lock.with_read_lock do
          return unless @is_active
          while line = socket.gets do
            req_id, req_loc, req_string = line.split(";")
            @service_strategy.add_request(req_id, req_loc, req_string)
          end
        end
      end

      def new_information(io, source)
        # get response from service strategy
        response, voi =
          @service_strategy.execute_service(io, source)

        # disseminate calls DisService
        @application.disseminate(response, voi)
      end

      # Sets this service as active.
      def activate
        @is_active_lock.with_write_lock do
          @is_active = true
        end
      end

      # Sets this service as inactive.
      def deactivate
        @is_active_lock.with_write_lock do
          @is_active = false
        end
      end

      # Returns true if this service is active, false otherwise.
      def active?
        @is_active_lock.with_read_lock do
          @is_active
        end
      end

      # TODO: implement this
      def update_configuration(new_conf)
      end

    end
  end
end
