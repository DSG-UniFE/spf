module SPF
  module Gateway
    class OCRServiceStrategy

      def initialize(priority, time_decay_rules, distance_decay_rules)
        @priority = priority
        @time_decay_rules = time_decay_rules.dup.freeze
        @distance_decay_rules = distance_decay_rules.dup.freeze
        @requests = {}
      end

      def add_request(req_id, req_loc, req_string)
        text_to_look_for =~ /find "(.+)"/

        (@requests[text_to_look_for] ||= []) << [req_id, req_loc]
      end

      def execute_service(io, source)
        requestors = 0
        closest_requestor_location = nil

        # find @requests.keys in io (Information Object)
        @requests.each do |k,v|
          if io =~ k
            requestors += v.size
            most_recent_request_time # TODO Mauro
            closest_requestor_location = bogus # TODO Marco
          end
        end

        # do not process unless we have requestors
        unless requestors
          voi = calculate_max_voi(requestors, most_recent_request_time, closest_requestor_location)
          p "#{io} found at #{source}" , voi
        end
      end

      private

        def calculate_max_voi(requestors, most_recent_request_time, closest_requestor_location)
          # VoI(o,r,t,a)= PA(a) * RN(r) * TRD(t,OT(o)) * PRD(OL(r),OL(o))
          p_a = @priority
          r_n = requestors / @max_number_of_requestors
          t_rd = apply_decay(Time.now - most_recent_request_time, @time_decay_rules)
          p_rd = apply_decay(GPS.distance(PIG.location, closest_requestor_location), @distance_decay_rules)
          p_a * r_n * t_rd * p_rd
        end

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
