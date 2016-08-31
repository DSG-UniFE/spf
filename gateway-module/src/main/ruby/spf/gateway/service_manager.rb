require 'timers'

module SPF
  module Gateway

    class ServiceManager
      
      # TODO make ServiceManager a Singleton and make sure that SPF::Gateway::Configuration  
      # does not create a second instance together with SPF::PIG
      
      # Initializes the service manager.
      def initialize
        @services = {}
        @active_pipelines = {}
        @timers = Timers::Group.new
      end
      
      # Instantiates the service_strategy based on the service_name.
      #
      # @param service_name [String] Name of the service to instantiate.
      # @param service_conf [Hash] Configuration of the service to instantiate.
      def self.service_strategy_factory(service_name, service_conf)
        svc = case service_name
        when :find_text
          FindTextServiceStrategy.new(service_conf[:priority],
                                      service_conf[:time_decay],
                                      service_conf[:distance_decay])
        when :listen
          # TODO
          raise "Unimplemented service"
        when :count
          raise "Unimplemented service"
        else
          raise "Unknown service"
        end
      end
      
      # Instantiates (creates and activates) a service.
      #
      # @param service_name [String] Name of the service to instantiate.
      # @param service_conf [Hash] Configuration of the service to instantiate.
      # @param application [SPF::Gateway::Application] The application the service to instantiate belongs to.
      def instantiate_service(service_name, service_conf, application)
        @services[application.name] ||= {}
        
        # create service if it does not exist
        svc = @services[application.name][service_name]
        if !@services.key?(application.name) || !@services[application.name].key?(service_name)
          svc_strategy = service_strategy_factory(application.name, service_conf)
          svc = Service.new(service_name, service_conf, application, svc_strategy, self)
          # add service to the set of services of corresponing application
          # TODO: we operate under the assumption that the (application_name,
          # service_name) couple is unique for each service. Make sure the
          # assumption holds, so that the following statement does not overwrite
          # anything!!!
          @services[application.name][service_name] = [svc, nil]  # [service, timer]
        end
        
        # ...and activate it
        activate_service(svc)
      end

      def get_service_by_name(application_name, service_name)
        # TODO: we operate under the assumption that the (application_name,
        # service_name) couple is unique for each service. Make sure the
        # assumption holds, so that the following statement returns just one service.
        @services[application_name][service_name][0]
      end

      # Resets the timer associated to the service svc
      #
      # @param svc [SPF::Gateway::Service] The service whose timer needs to be reset.
      def reset_timer(svc)
        timer = @services[svc.application.name][svc.name][1]
        return if timer.nil?
        timer.reset() unless timer.paused? 
      end

      def with_pipelines_interested_in(raw_data)
        interested_pipelines = @active_pipelines.select {|p| p.interested_in?(raw_data) }

        interested_pipelines.each do |p|
          yield p
        end
      end

      private

        # Activates a service
        #
        # @param svc [SPF::Gateway::Service] the service to activate.
        def activate_service(svc) # max_time?
          # if a service has a maximum instantiation time, schedule its
          # deinstantiation
          if svc.max_idle_time
            active_timer = @timers.after(svc.max_time) { deactivate_service(svc) }
            @services[svc.application.name][svc.name] = [svc, active_timer]
          end

          # instantiate pipeline if needed
          pipeline = @active_pipelines[svc.pipeline]
          unless pipeline
            pipeline = case svc.pipeline
            when :ocr
              # TODO: pass as parameter what the pipeline should look for?
              # activate OCR pipeline
              @active_pipelines[:ocr] =
                Pipeline.new(OCRProcessingStrategy.new)
            when :audio
              # TODO
            when :object_count
              # TODO
            else
              raise "Unknown pipeline"
            end
          end

          pipeline.register_service(svc)
        end

        # Deactivates a service
        #
        # @param svc [SPF::Gateway::Service] The service to deactivate.
        def deactivate_service(svc)
          # TODO: this method is going to be called by a block of code inside a timer --> check thread safety

          # remove service
          #@services[svc.application.name].delete(svc.name) # TODO ask Mauro if this line is equivalent to the following one
          @services[svc.application.name][svc.name] = [nil, nil]

          # find pipeline
          @active_pipelines.each do [pl]
            pl.unregister_service(svc)
          end

          # delete useless pipelines
          @active_pipelines.delete_if { |pl| !pl.has_services? }
          
          
          #pl = @active_pipelines[svc.pipeline]

          # raise error if pipeline state is inconsistent
          #raise "Inconsistent state in ServiceManager!" unless pl

          # remove service from pipeline
          #pl[:related_services].delete(svc)

          # deactivate pipeline if needed
          #if pl[:related_services].empty?
            #pl[:pipeline].deactivate
          #end
        end
    end

  end
end
