require 'json'
require 'java'

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

        response = JSON.parse(io)
        status = response['status'] #usually it's 'ok'
        results = response['results'] #list of results

        return "failed", 0 if results.length == 0 or status.eql? "ok"

        #Else find the result with the best score
        max_score = 0.0
        id_res = ""
        results.each do |el|
          max_score = el['score'] and id_res = el['id'] if el['score'] > max_score
        end

        #Get the best match and retrieve artist,title and other info
        best_match = results[id_res]
        score = best_match['recordings']['score'] #number between 0 and 1, quality of the audio match

        requestors = 0
        closest_requestor_location = nil

        # find @requests.keys in IO (Information Object)
        @requests.each do |k,v|
            requestors += v.size
            most_recent_request_time = calculate_most_recent_time(v)
            closest_requestor_location = calculate_closest_requestor_location(v)
        end

        # process IO unless we have no requestors
        unless requestors.zero?
          voi = calculate_max_voi(score, requestors, most_recent_request_time, closest_requestor_location)
          return best_match , voi
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