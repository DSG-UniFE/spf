module SPF
  module Gateway
    class FindTextServiceStrategy

      def initialize(priority, time_decay_rules, distance_decay_rules)
        @priority = priority
        @time_decay_rules = time_decay_rules.dup.freeze
        @distance_decay_rules = distance_decay_rules.dup.freeze
        @requests = {}
      end

      def add_request(req_id, req_loc, req_string)
        text_to_look_for = /find "(.+?)"/.match(req_string)[0]

        (@requests[text_to_look_for] ||= []) << [req_id, req_loc, Time.now]
      end

      def execute_service(io, source)
        requestors = 0
        closest_requestor_location = nil

        # find @requests.keys in IO (Information Object)
        @requests.each do |k,v|
          if io =~ Regexp.new(k)
            requestors += v.size
            most_recent_request_time = calculate_most_recent_time(v) # TODO Mauro
            closest_requestor_location = calculate_closest_requestor_location(v) # TODO Marco
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
        
        def calculate_most_recent_time(value)
          
          #time of the first request in the array
          time = value[0][2]
          
          # value ~  [[req1_id , req1_loc, req1_time], [req2_id , req2_loc, req2_time], ... ]
          value.each do |v| 
          
              if v[2] > time
                time = v[2]
              end
           
          return time   
        end
        
        def calculate_closest_requestor_location(value)
          
          #distance between first request in the array and PIG location
          min_distance = SPF::Gateway::GPS.new(PIG.location, value[0][1]).distance
          
          value.each do |v|
            new_distance = SPF::Gateway::GPS.new(PIG.location, v[1]).distance
            min_distance = new_distance if  new_distance < min_distance
          end 
          
          return d
        end
            
   end
  end
 end
end
