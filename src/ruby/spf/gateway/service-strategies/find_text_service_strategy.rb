require 'spf/common/exceptions'
require 'spf/common/extensions/fixnum'
require 'spf/common/decay_applier'
require 'spf/common/voi_utils'

module SPF
  module Gateway

    class FindTextServiceStrategy

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
        @time_decay_rules = time_decay_rules.nil? || time_decay_rules[:type].nil? || time_decay_rules[:max].nil?? @@DEFAULT_TIME_DECAY.dup.freeze : time_decay_rules.dup.freeze
        # @time_decay_rules = time_decay_rules.dup.freeze
        @distance_decay_rules = distance_decay_rules.nil? || distance_decay_rules[:type].nil? || distance_decay_rules[:max].nil? ? @@DEFAULT_DISTANCE_DECAY.dup.freeze : distance_decay_rules.dup.freeze
        @requests = {}
      end

      def add_request(user_id, req_loc, req_string)
        text_to_look_for = /find '(.+?)'/i.match(req_string)

        raise SPF::Common::Exceptions::WrongServiceRequestStringFormatException,
          "*** PIG: String <#{req_string}> has the wrong format ***" if text_to_look_for.nil?
        raise SPF::Common::PipelineNotActiveException,
          "*** #{self.class.name}: Pipeline OCR/OpenOCR not active ***" unless
          @pipeline_names.include?(:ocr) || @pipeline_names.include?(:open_ocr)

        (@requests[text_to_look_for[1]] ||= []) << [user_id, req_loc, Time.now]
      end

      def has_requests_for_pipeline(pipeline_id)
        @pipeline_names.include?(pipeline_id) && !@requests.empty?
      end

      def execute_service(io, source, pipeline_id)
        requestors = 0
        most_recent_request_time = 0
        closest_requestor_location = nil
        instance_string = ""
        delete_requests = {}

        # find @requests.keys in IO
        @requests.each do |key, requests|
          remove_expired_requests(requests, @time_decay_rules[:max])
          if requests.empty?
            delete_requests[key] = true
            next
          end

          unless (io =~ Regexp.new(key, Regexp::IGNORECASE)).nil?
            requestors += requests.size
            most_recent_request_time = calculate_most_recent_time(requests)
            closest_requestor_location = calculate_closest_requestor_location(requests)
            instance_string += key + ";"
            delete_requests[key] = true
          end

        end
        instance_string.chomp!(";")
        @requests.delete_if { |key, value| delete_requests.has_key?(key) || value.nil? || value.empty? }

        # process IO unless we have no requestors
        unless requestors.zero?
          voi = calculate_max_voi(1.0, requestors, source, most_recent_request_time, closest_requestor_location)
          return instance_string, io, voi
        end

        return nil, io, 0
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
            time = r[2] if r[2] > time
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
