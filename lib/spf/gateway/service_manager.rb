require 'timers'

module SPF
  module Gateway

    class ServiceManager
      # Initializes the service manager.
      def initialize
        @services = {}
        @active_pipelines = {}
        @timers = Timers::Group.new
      end

      # Instantiates (creates and activates) a service.
      #
      # @param service_name [String] Name of the service to instantiate.
      # @param config [String] Configuration of the service to instantiate.
      # @param application [SPF::Gateway::Application] The application the service to instantiate belongs to.
      def instantiate_service(service_name, config, application)
        # create service...
        svc = Service.new(service_name, config, application, self)

        # add service to the set of services of corresponing application
        @services[application.name] ||= {}
        # TODO: we operate under the assumption that the (application_name,
        # service_name) couple is unique for each service. Make sure the
        # assumption holds, so that the following statement does not overwrite
        # anything!!!
        @services[application.name][service_name] = svc

        # ...and activate it
        activate_service(svc)
      end

      def get_service_by_name(application_name, service_name)
        # TODO: we operate under the assumption that the (application_name,
        # service_name) couple is unique for each service. Make sure the
        # assumption holds, so that the following statement returns just one service.
        @services[application_name][service_name]
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
          if svc.max_time
            @timers.after(svc.max_time) { deactivate_service(svc) }
          end

          # instantiate pipeline if needed
          pipeline = @active_pipelines[svc.pipeline]
          unless pipeline
            pipeline = case svc.pipeline
            when :ocr
              # TODO: pass as parameter what the pipeline should look for?
              # activate OCR pipeline
              @active_pipelines[:ocr] =
                Pipeline.new(svc.tau, OCRProcessingStrategy.new("water"))
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
          # this method is going to be called by a block of code inside a timer

          # remove service
          @services[svc.application.name].delete(svc.name)

          # find pipeline
          pl = @active_pipelines[svc.pipeline]

          # raise error if pipeline state is inconsistent
          raise "Inconsistent state in ServiceManager!" unless pl

          # remove service from pipeline
          pl[:related_services].delete(svc)

          # deactivate pipeline if needed
          if pl[:related_services].empty?
            pl[:pipeline].deactivate
          end
        end
    end

  end
end
