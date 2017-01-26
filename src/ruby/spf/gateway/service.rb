require 'forwardable'
require 'concurrent'

require_relative './gps'


module SPF
  module Gateway
    class Service

      include SPF::Logging

      @@DEFAULT_TAU = 0.10

      # Dissemination is handled at the application level.
      extend Forwardable
      def_delegator :@application, :disseminate

      attr_reader :name, :tau, :max_idle_time, :application, :on_demand, :pipeline_names

      # Create service.
      #
      # @param name [Symbol] The service name.
      # @param configuration [Hash] The service configuration.
      # @param application [SPF::Gateway::Application] The application this service refers to.
      # @param service_strategy [SPF::Gateway::Service_Strategy] An object that implements the
      #                                                          Service_Strategy interface.
      def initialize(name, service_conf, application, service_strategy)
        @name = name
        @pipeline_names = []
        service_conf[:processing_pipelines].each do | pipeline |
          @pipeline_names << pipeline.to_sym
        end
        @tau = service_conf[:filtering_threshold].nil? ? @@DEFAULT_TAU : service_conf[:filtering_threshold]
        @on_demand = service_conf[:on_demand]
        @max_idle_time = service_conf[:uninstall_after]
        @response_expiration_time = service_conf[:expire_after]
        @service_strategy = service_strategy
        @application = application
        @is_active = false
        @is_active_lock = Concurrent::ReadWriteLock.new
      end

      def register_request(request_line)
        req_string = ""
        @is_active_lock.with_read_lock do
          return unless @is_active
          user_id, req_loc, req_string = request_line.split(";")
          @service_strategy.add_request(user_id, req_loc, req_string)
        end
        logger.info "*** #{self.class.name}: registered new request: #{req_string[0,-1]} ***"
      end

      def new_information(io, source, pipeline_id)
        logger.info "*** #{self.class.name}: received new IO from #{source} ***"
        # get response from service strategy
        instance_string, response, voi  = @service_strategy.execute_service(io, source, pipeline_id)

        if response.nil?
          logger.info "*** #{self.class.name}: no IOs available to disseminate ***"
        else
          # disseminate calls DisService
          @application.disseminate(@name.to_s, instance_string, @service_strategy.mime_type,
                                   response, voi, response_expiration_time)
        end
      end

      # Sets this service as active.
      def activate
        @is_active_lock.with_write_lock do
          @is_active = true
        end
        logger.info "*** #{self.class.name}: Service #{@name} actived ***"
      end

      # Sets this service as inactive.
      def deactivate
        @is_active_lock.with_write_lock do
          @is_active = false
        end
        logger.info "*** #{self.class.name}: Service #{@name} deactived ***"
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

      def get_pipeline_id_from_request(req_string)
        @service_strategy.get_pipeline_id_from_request(@pipeline_names,req_string)
      end

    end
  end
end
