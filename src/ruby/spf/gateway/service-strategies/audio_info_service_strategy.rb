require 'json'

require 'spf/common/decay_applier'

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


      def initialize(priority, pipeline_names, time_decay_rules=@@DEFAULT_TIME_DECAY, distance_decay_rules=@@DEFAULT_DISTANCE_DECAY)
        @priority = priority
        @pipeline_names = pipeline_names
        @time_decay_rules = time_decay_rules.nil? || time_decay_rules[:type].nil? || time_decay_rules[:max].nil? ? @@DEFAULT_TIME_DECAY.dup.freeze : time_decay_rules.dup.freeze
        @distance_decay_rules = distance_decay_rules.nil? || distance_decay_rules[:type].nil? || distance_decay_rules[:max].nil? ? @@DEFAULT_DISTANCE_DECAY.dup.freeze : distance_decay_rules.dup.freeze
        @requests = {}
      end

      def add_request(user_id, req_loc, req_string)
        req_type = case req_string
          when /recognize song/
            raise SPF::Common::PipelineNotActiveException,
              "*** #{self.class.name}: Pipeline Audio Recognition not active ***" unless
              @pipeline_names.include?(:audio_recognition)
            :audio_recognition
          else
            raise SPF::Common::WrongServiceRequestStringFormatException,
               "*** #{self.class.name}: No pipeline matches #{req_string} ***"
        end
        
        (@requests[req_type] ||= []) << [user_id, req_loc, Time.now]
      end
      
      def has_requests_for_pipeline(pipeline_id)
        @requests.has_key?(pipeline_id)
      end

      #FORMAT OF THE RESPONSE
      # {{'status': 'ok', 'results':
      # [{'recordings':
      # [{'duration': 265, 'artists':
      # [{'id': 'cbcab74a-7064-4068-a622-0e53903e729a',
      # 'name': 'Comando Souto'}], 'id': '4e0c7d75-898b-4a83-bb70-2347443c8a59',
      # 'title': 'Zumba'}], 'score': 0.888713, 'id': '91aef013-274f-4510-b9b9-9a5316f6631b'}]}}
      def execute_service(io, source, pipeline_id)
        puts "Audio info execute_service: 'io' = #{io}"
        response = JSON.parse(io)
        
        return nil, nil, 0  if response['status'] == "error"    #usually it's 'ok'

        results = response['results'] #list of results
        return nil, nil, 0 if results.empty?
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
          if requests.empty?
            next
          end
          
          requestors += requests.size
          most_recent_request_time = calculate_most_recent_time(requests)
          closest_requestor_location = calculate_closest_requestor_location(requests)
        end
          
        @requests.clear

        # process IO unless we have no requestors
        unless requestors.zero?
          voi = calculate_max_voi(score, requestors, source, most_recent_request_time, closest_requestor_location)
          return instance_string, best_match, voi
        end
        
        return nil, nil, 0
      end

      def mime_type
        @@MIME_TYPE
      end


      private

        def calculate_max_voi(io_quality, requestors, source, most_recent_request_time, closest_requestor_location)
          # VoI(o,r,t,a)= QoI(a) * PA(a) * RN(r) * TRD(t,OT(o)) * PRD(OL(r),OL(o))
          qoi = io_quality
          p_a = @priority
          r_n = requestors / SPF::Gateway::Service.get_set_max_number_of_requestors(requestors)
          t_rd = SPF::Common::DecayApplier.apply_decay(Time.now - most_recent_request_time, @time_decay_rules)
          location = source.nil? ? PIG.location : source
          p_rd = SPF::Common::DecayApplier.apply_decay(SPF::Gateway::GPS.new(location, closest_requestor_location).distance, @distance_decay_rules)
          qoi * p_a * r_n * t_rd * p_rd
        end

        def calculate_most_recent_time(requests)
          #time of the first request in the array
          time = requests[0][2]
          # requests ~ [[req1_id , req1_loc, req1_time], [req2_id , req2_loc, req2_time], ... ]
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
