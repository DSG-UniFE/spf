require 'timers'
require 'singleton'

module SPF
  module Gateway

    class ServiceManager
      include Singleton
      
      @@PROCESSING_STRATEGY_FACTORY = {
        :ocr => OCRProcessingStrategy,
        :object_count => ObjectCountProcessingStrategy,
        :identify_song => IdentifySongProcessingStrategy,
        :face_recognition => FaceRecognitionProcessingStrategy
      }
      
      @@SERVICE_STRATEGY_FACTORY = {
        :basic => BasicServiceStrategy,
        :find_text => FindTextServiceStrategy,
        :listen => AudioInfoServiceStrategy
      }
      
      
      # Initializes the service manager.
      def initialize
        @services = {}
        @services_lock = Concurrent::ReadWriteLock.new
        @active_pipelines = {}
        @active_pipelines_lock = Concurrent::ReadWriteLock.new
        @timers = Timers::Group.new
      end
      
      # Instantiates (creates and activates) a service.
      #
      # @param service_name [String] Name of the service to instantiate.
      # @param service_conf [Hash] Configuration of the service to instantiate.
      # @param application [SPF::Gateway::Application] The application the service to instantiate belongs to.
      def instantiate_service(service_name, service_conf, application)
        @services_lock.with_write_lock do
          # retrieve service location in @services
          @services[application.name] ||= {}
          @services[application.name][service_name] ||= [nil, nil]
          svc = @services[application.name][service_name][0]
          
          # create service if it does not exist...
          unless svc
            svc_strategy = service_strategy_factory(application.name, service_conf)
            svc = Service.new(service_name, service_conf, application, svc_strategy)
            # add service to the set of services of corresponing application
            # TODO: we operate under the assumption that the (application_name,
            # service_name) couple is unique for each service. Make sure the
            # assumption holds, so that the following statement does not overwrite
            # anything!!!
            @services[application.name][service_name] = [svc, nil]  # [service, timer]
          end
        end
        
        # ...and activate it!
        # TODO: or postopone activation until the first request arrives? 
        activate_service(svc)
      end
      
      # Instantiates (creates and activates) a service.
      #
      # @param service_name [SPF::Gateway::Service] Instance of the service to reactivate.
      def restart_service(svc)
        # do nothing if the service was not configured before
        @services_lock.with_read_lock do
          return if @services[application_name].nil? ||
            @services[application_name][service_name].nil?
        end
                
        # reactivate the service
        activate_service(svc)
      end

      # Finds the service from the pair application_name:service_name 
      # provided in the parameters and resets any timer associated
      # to that service.
      #
      # @param application_name [String] Name of the application.
      # @param service_name [String] Name of the service to find.
      def get_service_by_name(application_name, service_name)
        # TODO: we operate under the assumption that the (application_name,
        # service_name) couple is unique for each service. Make sure the
        # assumption holds, so that the following statement returns just one service.
        @services_lock.with_read_lock do
          return if @services[application_name].nil? ||
            @services[application_name][service_name].nil?
          
          svc_timer_pair = @services[application_name][service_name]
          reset_timer(svc_timer_pair[1])
          svc_timer_pair[0]
        end
      end

      # Executes the block of code for each pipeline p 
      # interested in the raw_data passed as a parameter
      #
      # @param raw_data [string] The string of bytes contained in the UDP    
      #                          message received from the network.
      def with_pipelines_interested_in(raw_data)
        @active_pipelines_lock.with_read_lock do
          interested_pipelines = @active_pipelines.select {|pl_sym, pl| pl.interested_in?(raw_data) }
          interested_pipelines.each do |pl|
            yield pl
          end
        end
      end
      
      
      private

      # Instantiates the service_strategy based on the service_name.
      #
      # @param service_name [String] Name of the service to instantiate.
      # @param service_conf [Hash] Configuration of the service to instantiate.
      def self.service_strategy_factory(service_name, service_conf)
        raise "Unknown service" if @@SERVICE_STRATEGY_FACTORY[service_name].nil?
        svc = @@SERVICE_STRATEGY_FACTORY[service_name].new(
          service_conf[:priority], service_conf[:time_decay], service_conf[:distance_decay])
      end

      # Instantiates the processing_strategy based on the service_name.
      #
      # @param processing_strategy_name [String] Name of the processing_strategy to instantiate.
      def self.processing_strategy_factory(processing_strategy_name)
        raise "Unknown processing pipeline" if
          @@PROCESSING_STRATEGY_FACTORY[processing_strategy_name].nil?
        @@PROCESSING_STRATEGY_FACTORY[processing_strategy_name].new
      end

      # Activates a service
      #
      # @param svc [SPF::Gateway::Service] the service to activate.
      def activate_service(svc) # max_time?
        # do nothing if service is already active
        return if svc.active?
        
        # if a service has a maximum idle lifetime, schedule its deactivation
        @services_lock.with_write_lock do
          return if svc.active?
          if svc.max_idle_time
            active_timer = @timers.after(svc.max_time) { deactivate_service(svc) }
            @services[svc.application.name][svc.name][1] = active_timer
          end
          
          # instantiate pipeline if needed
          @active_pipelines_lock.with_read_lock do
            pipeline = @active_pipelines[svc.pipeline_name]
          end
          unless pipeline
            @active_pipelines_lock.with_write_lock do
              # check again in case another thread has acquired 
              # the write lock and changed @active_pipelines
              pipeline = @active_pipelines[svc.pipeline_name]
              pipeline = Pipeline.new(
                processing_strategy_factory(svc.pipeline_name)) unless pipeline
            end
          end
  
          # register the new service with the pipeline and activate the service
          pipeline.register_service(svc)
          svc.activate
        end
      end

      # Deactivates a service
      #
      # @param svc [SPF::Gateway::Service] The service to deactivate.
      def deactivate_service(svc)
        # TODO: this method is going to be called by a block of code inside a timer --> check thread safety
        # deactivate the service if active
        return unless svc.active?
        
        @services_lock.with_write_lock do
          return unless svc.active?
          svc.deactivate
    
          # remove timer associated to service
          remove_timer(svc)

          @active_pipelines_lock.with_write_lock do
            # unregister pipelines registered with the service
            @active_pipelines.each_value do [pl]
              pl.unregister_service(svc)
            end
    
            # delete useless pipelines
            @active_pipelines.keep_if { |pl_sym, pl| pl.has_services? }
          end
        end
      end

      # Removes the timer associated to the service svc
      #
      # @param svc [SPF::Gateway::Service] The service whose timer needs to be removed.
      def remove_timer(svc)
        @services[svc.application.name][svc.name][1] = nil
      end
      
      # Resets the timer associated to the service svc
      #
      # @param svc [SPF::Gateway::Service] The service whose timer needs to be reset.
      def reset_timer(timer)
        return if timer.nil?
        timer.reset() unless timer.paused? 
      end
      
    end
  end
end
