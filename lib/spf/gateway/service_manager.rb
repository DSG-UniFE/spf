require 'timers'

module SPF
  module Gateway

    class ServiceManager
      def initialize
        @services = {}
        @active_pipelines = {}
        @timers = Timers::Group.new
      end

      # Registers service
      #
      # @param svc [SPF::Gateway::Service] the service to register
      def register_service(svc) # max_time?
        # add service to the set of services of corresponing type
        (@services[svc.svc_type] ||= Set.new) << svc

        # if a service has a maximum instantiation time, schedule its
        # deinstantiation
        if svc.max_time
          @timers.after(svc.max_time) { unregister_service(svc) }
        end

        # instantiate pipeline if needed
        pipeline = @active_pipelines[svc.pipeline]
        if pipeline
          unless pipeline[:related_services].includes? svc
            pipeline[:related_services] << svc
          end
        else
          case svc.pipeline
          when :ocr
            # activate OCR pipeline
            @pipelines[:ocr] = {
              pipeline: OCRPipeline.new,
              related_services: Set.new[ svc ]
            }
          when :audio
            # TODO
          when :object_count
            # TODO
          end
        end
      end

      # # do we actually need this method? isn't get_services_of_type enough?
      # def has_services_of_type?(svc_type)
      #   @services.has_key?(svc_type) and !@services[svc_type].empty?
      # end

      # Returns all the registered services of a given type.
      #
      # @param [Symbol] The type of service the caller is interested in.
      # @return [Set] The set of services of requested type (or nil if empty).
      def get_services_of_type(svc_type)
        @services[svc_type]
      end

      private

        def unregister_service(service)
          # this is going to be called by a block of code inside a timer
          # TODO
        end
    end

  end
end
