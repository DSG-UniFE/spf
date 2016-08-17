module SPF
  module Gateway
    class Service
      attr_reader :type

      # Create service.
      #
      # @param name [String] The service name.
      # @param configuration [Hash] The service configuration.
      # @param application [SPF::Gateway::Application] The application this service refers to.
      # @param service_manager [SPF::Gateway::ServiceManager] The PIG ServiceManager instance.
      def initialize(name, configuration, application, service_manager)
        @application = application
        @service_manager = service_manager
        @type = type

        if configuration[:time_decay]
          @time_decay_rules = configuration[:time_decay].dup.freeze
        end

        if configuration[:distance_decay]
          @distance_decay_rules = configuration[:distance_decay].dup.freeze
        end

        #@closest_requestor_location = nil
        @most_recent_request = nil
        #@requestors = Set.new # TODO: check
        #@max_number_of_requestors = 0
        @requests = {}
      end

      def time_decay(initial_value, elapsed_time)
        if @time_decay_type == :exponential
          exponential_decay(initial_value, elapsed_time, @time_decay_constant)
        else # :linear
          linear_decay(initial_value, elapsed_time, @time_decay_constant)
        end
      end

      def distance_decay(initial_value, elapsed_time)
        if @distance_decay_type == :exponential
          exponential_decay(initial_value, elapsed_time, @time_decay_constant)
        else # :linear
          linear_decay(initial_value, elapsed_time, @distance_decay_constant)
        end
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
        t_rd = apply_decay(Time.now - @most_recent_request.time, @time_decay_rules)
        p_rd = apply_decay(GPS.calculate_distance(PIG.location, @closest_requestor_location), @distance_decay)
        p_a * r_n * t_rd * p_rd
      end

      private

        def apply_decay(value, rules)
          # enforce maximum value if needed
          return 0.0 if rules[:max] and value > rules[:max]

          # apply decay according to the requested type
          decay_modifier = case rules[:type]
          when :exponential
            Math.exp(-value)
          when :linear
            1.0 - value / rules[:max].to_f
          else
            1.0 # default is no decay at all
          end

          # apply decay modifier to value
          value * decay_modifier
        end
    end
  end
end
