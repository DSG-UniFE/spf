module SPF
  module Gateway
    class Service
      def initialize(app, pipeline)
        @application = app
        @processing_pipeline = pipeline

        @closest_requestor_location = nil
        @most_recent_request = nil
        @requestors = Set.new # TODO: check
        @max_number_of_requestors = 0
      end

      def register_request(req)
        # TODO: update closest_recipient
        req.users.each do |user|
          @requestors.add(user)
        end

        # update @max_number_of_requestors
        if @requestors.size > @max_number_of_requestors
          @max_number_of_requestors = @requestors.size
        end

        # TODO: update @closest_requestor_location
        @closest_requestor_location = ...

        # update @most_recent_request
        @most_recent_request = req
      end

      def unregister_request(req)
        # TODO: update closest_recipient
        req.users.each do |user|
          @requestors.delete(req.user)
        end

        # TODO: update @most_recent_request

        # TODO: update @closest_requestor_location
      end

      def new_data(raw_data)
        # do not process unless we have requestors
        return unless @requestors.size

        # do the actual processing
        io = @processing_pipeline.process(raw_data) # services might share pipelines

        # if raw_data was not different enough from previously processed
        # raw_data, it won't be processed
        return unless io

        # calculate voi
        voi = calculate_max_voi(io)

        # disseminate calls DisService
        @app.disseminate(io, voi)
      end

      def calculate_max_voi
        # VoI(o,r,t,a)= PA(a) * RN(r) * TRD(t,OT(o)) * PRD(OL(r),OL(o))
        p_a = @app.priority
        r_n = @requestors.size / @max_number_of_requestors
        t_rd = @app.time_decay(Time.now,
                               @most_recent_request.time)
        p_rd = @app.distance_decay(PIG.location,
                                   @closest_requestor_location)
        p_a * r_n * t_rd * p_rd
      end
    end
  end
end
