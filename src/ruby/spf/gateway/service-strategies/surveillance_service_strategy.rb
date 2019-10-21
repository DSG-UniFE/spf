require 'java'
require 'matrix'

require 'spf/common/exceptions'
require 'spf/common/decay_applier'
require 'spf/common/voi_utils'
require 'spf/gateway/pig'
require 'spf/gateway/service'

require_relative './basic_service_strategy'


module SPF
  module Gateway
    class SurveillanceServiceStrategy < SPF::Gateway::BasicServiceStrategy

      include SPF::Common::VoiUtils
      include SPF::Common::DecayApplier


      def initialize(priority, pipeline_names, time_decay_rules, distance_decay_rules)
        super(priority, pipeline_names, time_decay_rules, distance_decay_rules, self.class.name)
        @content_type = "text/plain"
      end

      def add_request(user_id, req_loc, req_string)
        req_type = case req_string
          when /count objects/
            raise SPF::Common::PipelineNotActiveException,
              "*** #{self.class.name}: Pipeline Count Object not active ***" unless
              @pipeline_names.include?(:object_count)
            :object_count
          when /count people/
            raise SPF::Common::PipelineNotActiveException,
              "*** #{self.class.name}: Pipeline Face Detection not active ***" unless
              @pipeline_names.include?(:face_detection)
            :face_detection
          else
            raise SPF::Common::WrongRawDataReadingException,
               "*** #{self.class.name}: No pipeline matches #{req_string} ***"
        end

        (@requests[req_type] ||= []) << [user_id, req_loc, Time.now]
      end

      def execute_service(io, source, pipeline_id)
        requestors = 0
        most_recent_request_time = 0
        min_distance_to_requestor = Float::INFINITY
        source = PIG.location if source.nil?

        if @requests.has_key?(pipeline_id)
          requests = @requests[pipeline_id]
          remove_expired_requests(requests, @time_decay_rules[:max])
          if requests.empty?
            @requests.delete(pipeline_id)
            return nil, io, 0
          end

          # Normalized requests
          requestors = requests.size
          r_n = requestors.to_f / Service.get_set_max_number_of_requestors(requestors)

          # Time decay factor
          most_recent_request_time = most_recent_time(Matrix[*requests].column(2).to_a)
          t_rd = apply_decay(Time.now - most_recent_request_time, @time_decay_rules)

          # Distance decay factor
          min_distance_to_requestor = distance_to_closest_requestor(Matrix[*requests].column(1).to_a, source)
          p_rd = apply_decay(min_distance_to_requestor, @distance_decay_rules)

          voi = calculate_voi(1.0, @priority, r_n, t_rd, p_rd)

          # Build instance_string
          instance_string = case pipeline_id
            when :object_count
              "count objects"
            when :face_detection
              "count people"
          end
          instance_string += ";" + requestors.to_s
          puts "is: #{instance_string}, io: #{io}"

          @requests.delete(pipeline_id)

          return instance_string, io, voi
        end
        puts "no key #{io}"
        return nil, io, 0
      end

    end
  end
end
