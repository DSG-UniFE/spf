require 'forwardable'
require 'concurrent'


module SPF
  module Gateway
    class Service

      include SPF::Logging

      @@DEFAULT_TAU = 0.10
      @@MAX_NUMBER_OF_REQUESTORS = 0
      @@MAX_NUMBER_MUTEX = Mutex.new
      # Dissemination is handled at the application level.
      extend Forwardable
      def_delegator :@application, :disseminate
      def_delegator :@service_strategy, :has_requests_for_pipeline

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
        @response_expiration_time = service_conf[:expire_after] * 1000    # in milliseconds
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
          lat, lon = req_loc.split(',')
          req_loc = Hash.new
          req_loc[:lat] = lat
          req_loc[:lon] = lon
          @service_strategy.add_request(user_id, req_loc, req_string)
        end
        logger.info "*** #{self.class.name}: registered new request: #{req_string[0...-1]} ***"
      end

      def new_information(io, source, pipeline_id)
        if source.nil?
          logger.info "*** #{self.class.name}: received new IO from unknown location ***"
        else
          logger.info "*** #{self.class.name}: received new IO from #{source} ***"
        end
        # get response from service strategy
        instance_string, response, voi  = @service_strategy.execute_service(io, source, pipeline_id)

        if response.nil?
          logger.info "*** #{self.class.name}: no IOs available to disseminate ***"
        elsif instance_string.nil?
          logger.info "*** #{self.class.name}: no requests received ***"
        else
          # disseminate calls DisService
          @application.disseminate(@name.to_s, instance_string, @service_strategy.mime_type,
                                   response, voi, @response_expiration_time, source)
        end
      end

      # Sets this service as active.
      def activate
        @is_active_lock.with_write_lock do
          @is_active = true
        end
        logger.info "*** #{self.class.name}: Service #{@name} activated ***"
      end

      # Sets this service as inactive.
      def deactivate
        @is_active_lock.with_write_lock do
          @is_active = false
        end
        logger.info "*** #{self.class.name}: Service #{@name} deactivated ***"
      end

      # Returns true if this service is active, false otherwise.
      def active?
        @is_active_lock.with_read_lock do
          @is_active
        end
      end

      def self.get_set_max_number_of_requestors(requestors)
        return @@MAX_NUMBER_OF_REQUESTORS if requestors <= @@MAX_NUMBER_OF_REQUESTORS
        @@MAX_NUMBER_MUTEX.synchronize do

          if requestors > @@MAX_NUMBER_OF_REQUESTORS
            @@MAX_NUMBER_OF_REQUESTORS = requestors
          end
        end
        @@MAX_NUMBER_OF_REQUESTORS
      end

      # TODO: implement this
      def update_configuration(new_conf)
      end

    end
  end
end
