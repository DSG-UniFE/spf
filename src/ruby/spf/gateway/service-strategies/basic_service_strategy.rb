require 'java'

require 'spf/common/exceptions'


module SPF
  module Gateway

    class BasicServiceStrategy

      @@DEFAULT_TIME_DECAY = {
        type: :linear,
        max: 5.minutes
      }
      @@DEFAULT_DISTANCE_DECAY = {
        type: :linear,
        max: 1.km
      }

      @@MIME_TYPE = "text/plain"


      def initialize(priority, pipeline_names, time_decay_rules=@@DEFAULT_TIME_DECAY, distance_decay_rules=@@DEFAULT_DISTANCE_DECAY)
        @priority = priority
        @pipeline_names = pipeline_names
        @time_decay_rules = time_decay_rules.nil? ? @@DEFAULT_TIME_DECAY.dup.freeze : time_decay_rules.dup.freeze
        @distance_decay_rules = distance_decay_rules.nil? ? @@DEFAULT_DISTANCE_DECAY.dup.freeze : distance_decay_rules.dup.freeze
        @requests = {}
      end

      def add_request(user_id, req_loc, req_string)
        req_type = nil
        case req_string
        when /count objects/
          raise SPF::Common::PipelineNotActiveException,
            "*** #{self.class.name}: Pipeline Count Object not active ***" unless
            @pipeline_names.include?(:object_count)
          req_type = :object_count
        when /count people/
          raise SPF::Common::PipelineNotActiveException,
            "*** #{self.class.name}: Pipeline Face Recognition not active ***" unless
            @pipeline_names.include?(:face_recognition)
          req_type = :face_recognition
        else
          raise SPF::Common::WrongServiceRequestStringFormatException,
             "*** #{self.class.name}: No pipeline matches #{req_string} ***"
        end
        
        (@requests[req_type] ||= []) << [user_id, req_loc, Time.now]
      end

      def execute_service(io, source, pipeline_id)
        requestors = 0
        most_recent_request_time = 0
        closest_requestor_location = nil
        instance_string = ""

        if @requests.has_key?(pipeline_id)
          remove_expired_requests(@requests[pipeline_id], @time_decay_rules[:max])
          if @requests[pipeline_id].empty?
            @requests.delete(pipeline_id)
            return nil, nil, 0
          end
          
          requestors = @requests[pipeline_id].size
          most_recent_request_time = calculate_most_recent_time(@requests[pipeline_id])
          closest_requestor_location = calculate_closest_requestor_location(@requests[pipeline_id])
          instance_string = case pipeline_id
            when :object_count
              "count objects"
            when :face_recognition
              "count people"
          end
          
          @requests.delete(pipeline_id)
        end

        # process IO unless we have no requestors
        unless requestors.zero?
          voi = calculate_max_voi(1.0, requestors, most_recent_request_time, closest_requestor_location)
          return instance_string, io, voi
        end
        
        return nil, nil, 0
      end

      def mime_type
        @@MIME_TYPE
      end

      def get_pipeline_id_from_request(req_string)
        case req_string
        when /count objects/
          raise SPF::Common::PipelineNotActiveException,
            "*** #{self.class.name}: Pipeline Count Object not active ***" unless
            @pipeline_names.include?(:object_count)
          :object_count
        when /count people/
          raise SPF::Common::PipelineNotActiveException,
            "*** #{self.class.name}: Pipeline Face Recognition not active ***" unless
            @pipeline_names.include?(:face_recognition)
          :face_recognition
        else
          raise SPF::Common::WrongServiceRequestStringFormatException,
             "*** #{self.class.name}: No pipeline matches #{req_string} ***"
        end
      end

      
      private

        def calculate_max_voi(io_quality, requestors, most_recent_request_time, closest_requestor_location)
          # VoI(o,r,t,a)= QoI(a) * PA(a) * RN(r) * TRD(t,OT(o)) * PRD(OL(r),OL(o))
          qoi = io_quality
          p_a = @priority
          r_n = requestors / @max_number_of_requestors
          t_rd = apply_decay(Time.now - most_recent_request_time, @time_decay_rules)
          p_rd = apply_decay(GPS.distance(PIG.location, closest_requestor_location), @distance_decay_rules)
          qoi * p_a * r_n * t_rd * p_rd
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

        def calculate_most_recent_time(requests)
          #time of the first request in the array
          time = requests[0][2]
          # requests ~ [[req1_id , req1_loc, req1_time], [req2_id , req2_loc, req2_time], ... ]
          requests.each do |r|
            time = r[2] if r[2] > time
          end
          
          time
        end

        def calculate_closest_requestor_location(requests)
          #distance between first request in the array and PIG location
          puts requests[0][1]
          min_distance = SPF::Gateway::GPS.new(PIG.location, requests[0][1]).distance
          requests.each do |r|
            new_distance = SPF::Gateway::GPS.new(PIG.location, r[1]).distance
            min_distance = new_distance if new_distance < min_distance
          end

          min_distance
        end

        def remove_expired_requests(requests, expiration_time)
          now = Time.now
          requests.delete_if { |req| req[2] + expiration_time < now }
        end

    end
  end
end
