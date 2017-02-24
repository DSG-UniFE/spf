require 'json'

require 'spf/common/decay_applier'
require 'spf/common/voi_utils'

module SPF
  module Gateway
    class AudioInfoServiceStrategy

      include SPF::Common::VoiUtils
      include SPF::Common::DecayApplier

      GPS = SPF::Common::GPS

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
        # puts "Audio info execute_service: 'io' = #{io}"
        response = JSON.parse(io)

        return nil, nil, 0  if response['status'] == "error"    # Usually is 'ok'

        results = response['results']
        return nil, "", 0 if results.empty?

        # Find the best match
        max_score = 0.0
        id_res = ""
        results.each do |el|
          max_score = el['score'].to_f and id_res = el['id'] if el['score'].to_f > max_score
        end
        best_match = results[id_res]

        requestors = 0
        most_recent_request_time = 0
        min_distance_to_requestor = Float::INFINITY
        source = PIG.location if source.nil?
        # find @requests.keys in IO (Information Object)
        @requests.each do |key, requests|
          remove_expired_requests(requests, @time_decay_rules[:max])
          next if requests.empty?

          requestors += requests.size

          time_a = Matrix[*requests].column(2).to_a
          loc_a = Matrix[*requests].column(1).to_a
          most_recent_request_time = [most_recent_request_time, most_recent_time(time_a)].max
          min_distance_to_requestor = [min_distance_to_requestor, distance_to_closest_requestor(loc_a, source)].min
        end
        @requests.clear

        # process IO unless we have no requestors
        unless requestors.zero?
          # instance_string is in the format TIME;SOURCE_GPS_COORDINATES;REQUESTORS_NUMBER
          instance_string = (Time.now - best_match['recordings']['duration']).strftime("%Y-%m-%d %H:%M:%S")
          instance_string += ";" + source + ";" + requestors.to_s

          score = best_match['recordings']['score']     # number between 0 and 1, quality of the audio match
          r_n = requestors / Service.get_set_max_number_of_requestors(requestors)
          t_rd = apply_decay(Time.now - most_recent_request_time, @time_decay_rules)
          p_rd = apply_decay(min_distance_to_requestor, @distance_decay_rules)
          voi = calculate_voi(score, @priority, r_n, t_rd, p_rd)

          return instance_string, best_match, voi
        end

        return nil, "", 0
      end

      def mime_type
        @@MIME_TYPE
      end


      private

        def remove_expired_requests(requests, expiration_time)
          now = Time.now
          requests.delete_if { |req| req[2] + expiration_time < now }
        end

    end
  end
end
