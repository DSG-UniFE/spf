require 'java'
require 'matrix'

require 'spf/common/exceptions'
require 'spf/common/decay_applier'
require 'spf/common/voi_utils'
require 'spf/common/gps'
require 'spf/gateway/pig'
require 'spf/gateway/service'


module SPF
  module Gateway

    class BasicServiceStrategy
      
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

        (@requests[req_type] ||= []) << [user_id, req_loc, Time.now]
      end

      def has_requests_for_pipeline(pipeline_id)
        @requests.has_key?(pipeline_id)
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
            return nil, io, 0
          end

          requestors = @requests[pipeline_id].size
          req_time_matrix = Matrix[*@requests[pipeline_id]]
          most_recent_request_time = most_recent_time(req_time_matrix.column(2).to_a)

          req_loc_matrix = Matrix[*@requests[pipeline_id]]
          location = source.nil? ? PIG.location : source
          closest_requestor_location = closest_requestor_location(req_loc_matrix.column(1).to_a, location)
          
          r_n = requestors.to_f / Service.get_set_max_number_of_requestors(requestors)
          t_rd = apply_decay(Time.now - most_recent_request_time, @time_decay_rules)
          
          p_rd = apply_decay(GPS.new(location, closest_requestor_location).distance, @distance_decay_rules)
          voi = calculate_max_voi(1.0, @priority, r_n, t_rd, p_rd)

          instance_string = case pipeline_id
            when :object_count
              "count objects"
            when :face_recognition
              "count people"
          end

          @requests.delete(pipeline_id)

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
