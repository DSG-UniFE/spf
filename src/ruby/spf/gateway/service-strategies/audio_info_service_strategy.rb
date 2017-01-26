require 'json'


module SPF
  module Gateway

    class AudioInfoServiceStrategy

      @@DEFAULT_TIME_DECAY = {
        type: :linear,
        max: 5.minutes
      }
      @@DEFAULT_DISTANCE_DECAY = {
        type: :linear,
        max: 1.km
      }

      @@MIME_TYPE = "text/plain"


      def initialize(priority, time_decay_rules=@@DEFAULT_TIME_DECAY, distance_decay_rules=@@DEFAULT_DISTANCE_DECAY)
        @priority = priority
        @time_decay_rules = time_decay_rules.nil? ? @@DEFAULT_TIME_DECAY.dup.freeze : time_decay_rules.dup.freeze
        @distance_decay_rules = distance_decay_rules.nil? ? @@DEFAULT_DISTANCE_DECAY.dup.freeze : distance_decay_rules.dup.freeze
        @requests = {}

      end

      def add_request(req_id, req_loc, req_string)
        (@requests[req_loc] ||= []) << [req_id, req_loc, Time.now]
      end

      #FORMAT OF THE RESPONSE
      # {{'status': 'ok', 'results':
      # [{'recordings':
      # [{'duration': 265, 'artists':
      # [{'id': 'cbcab74a-7064-4068-a622-0e53903e729a',
      # 'name': 'Comando Souto'}], 'id': '4e0c7d75-898b-4a83-bb70-2347443c8a59',
      # 'title': 'Zumba'}], 'score': 0.888713, 'id': '91aef013-274f-4510-b9b9-9a5316f6631b'}]}}
      def execute_service(io, source)
        puts "Audio info execute_service: 'io' = #{io}"
        response = JSON.parse(io)
        status = response['status'] #usually it's 'ok'
        case status
          when "error" then return response['error'] unless response['error'].nil?
        #when "ok" return response['results'] unless response['results'].nil?
        end

        results = response['results'] #list of results
        return "empty result" if results.empty?
        #return "failed", 0 if results.length == 0 or status.eql? "ok"

        #Else find the result with the best score
        max_score = 0.0
        id_res = ""
        results.each do |el|
          max_score = el['score'].to_f and id_res = el['id'] if el['score'].to_f > max_score
        end

        #Get the best match and retrieve artist,title and other info
        best_match = results[id_res]
        score = best_match['recordings']['score'] #number between 0 and 1, quality of the audio match

        requestors = 0
        most_recent_request_time = 0
        closest_requestor_location = nil
        # instance_string is in the format TIME;GPS_COORDINATES
        instance_string = (Time.now - best_match['recordings']['duration']).strftime("%Y-%m-%d %H:%M:%S")
        instance_string += "; " + PIG.location

        # find @requests.keys in IO (Information Object)
        @requests.each do |key, requests|
          remove_expired_requests(requests, @time_decay_rules[:max])
          requestors += requests.size
          most_recent_request_time = calculate_most_recent_time(requests)
          closest_requestor_location = calculate_closest_requestor_location(requests)
        end
        @request.clear

        # process IO unless we have no requestors
        unless requestors.zero?
          voi = calculate_max_voi(score, requestors, most_recent_request_time, closest_requestor_location)
          return instance_string, best_match, voi
        end
      end

      def mime_type
        @@MIME_TYPE
      end

      def get_pipeline_id_from_request(pipeline_names, req_string)
        raise SPF::Common::PipelineNotActiveException,
            "*** #{self.class.name}: Pipeline Audio Recognition not active ***" unless
            pipeline_names.include?(:audio_recognition)
        :audio_recognition
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
          # value ~  [[req1_id , req1_loc, req1_time], [req2_id , req2_loc, req2_time], ... ]
          requests.each do |r|
            time = r[2] if v[2] > time
          end

          time
        end

        def calculate_closest_requestor_location(requests)

          #distance between first request in the array and PIG location
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
