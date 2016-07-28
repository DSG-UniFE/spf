module SPF
  module Gateway
    class Service
      def initialize(svc_type, pipeline)
        #@application = app
        @svc_type = svc_type
        @processing_pipeline = pipeline

        #@closest_requestor_location = nil
        @most_recent_request = nil
        #@requestors = Set.new # TODO: check
        #@max_number_of_requestors = 0
        @requests = {}
      end

      def register_request(header, socket)
        # TODO: update closest_recipient
        #req.users.each do |user|
          #@requestors.add(user)
        #end

        # update @max_number_of_requestors
        #if @requestors.size > @max_number_of_requestors
         # @max_number_of_requestors = @requestors.size
        #end

        # TODO: update @closest_requestor_location
        #@closest_requestor_location = ...

        @requests[header[2]] = socket

        # update @most_recent_request
        @most_recent_request = header
      end

      def unregister_request(header)
        # TODO: update closest_recipient
        #req.users.each do |user|
          #@requestors.delete(req.user)
        #end
        
        #delete request and close socket if open
        @requests.delete(header[2]).close
        
        # TODO: update @most_recent_request

        # TODO: update @closest_requestor_location
      end

      def new_data(raw_data)
        # do not process unless we have requestors
        return unless @requests.size

        # do the actual processing
        io = @processing_pipeline.process(raw_data) # services might share pipelines

        # if raw_data was not different enough from previously processed
        # raw_data, it won't be processed
        return unless io

        # calculate voi
        #voi = calculate_max_voi(io)

        # disseminate calls DisService
        #@app.disseminate(io, voi)
        @requests.each_pair {|req_string, socket| socket.write(io) if io.include? req_string}
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
