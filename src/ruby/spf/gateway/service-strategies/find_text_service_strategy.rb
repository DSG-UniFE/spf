require 'spf/common/exceptions'
require 'spf/common/extensions/fixnum'
require 'spf/common/decay_applier'
require 'spf/common/voi_utils'

module SPF
  module Gateway

    class FindTextServiceStrategy
      
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
        min_distance_to_requestor = Float::INFINITY
        source = PIG.location if source.nil?
        instance_string = ""
        delete_requests = {}

        # find @requests.keys in IO
        @requests.each do |key, requests|
          remove_expired_requests(requests, @time_decay_rules[:max])
          next if requests.empty?
          
          unless (io =~ Regexp.new(key, Regexp::IGNORECASE)).nil?
            requestors += requests.size
            instance_string += key + ";"
            
            time_a = Matrix[*requests].column(2).to_a
            loc_a = Matrix[*requests].column(1).to_a
            most_recent_request_time = [most_recent_request_time, most_recent_time(time_a)].max
            min_distance_to_requestor = [min_distance_to_requestor, distance_to_closest_requestor(loc_a, source)].min
            
            delete_requests[key] = requests
          end
        end
        instance_string += requestors.to_s
        @requests.delete_if { |key, value| delete_requests.has_key?(key) || value.nil? || value.empty? }

        # process IO unless we have no requestors
        unless requestors.zero?
          r_n = requestors / Service.get_set_max_number_of_requestors(requestors)
          t_rd = apply_decay(Time.now - most_recent_request_time, @time_decay_rules)
          p_rd = apply_decay(min_distance_to_requestor, @distance_decay_rules)
          voi = calculate_voi(1.0, @priority, r_n, t_rd, p_rd)
          
          return instance_string, io, voi
        end

        return nil, io, 0
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
