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
        (@services[svc.type] ||= Set.new) << svc

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
            @active_pipelines[:ocr] = {
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
      # def has_services_of_type?(type)
      #   @services.has_key?(type) and !@services[type].empty?
      # end

      # Returns all the registered services of a given type.
      #
      # @param [Symbol] The type of service the caller is interested in.
      # @return [Set] The set of services of requested type (or nil if empty).
      def get_services_of_type(type)
        @services[type]
      end

      private

        def unregister_service(svc)
          # this method is going to be called by a block of code inside a timer

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
