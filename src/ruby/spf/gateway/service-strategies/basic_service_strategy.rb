require 'java'
require 'matrix'

require 'spf/common/exceptions'
require 'spf/common/decay_applier'
require 'spf/common/voi_utils'

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
          times = req_time_matrix.column(2).to_a
          most_recent_request_time = SPF::Common::VoiUtils.most_recent_time(times)
          location = source.nil? ? PIG.location : source

          req_loc_matrix = Matrix[*@requests[pipeline_id]]
          req_locations = req_loc_matrix.column(1).to_a
          closest_requestor_location = SPF::Common::VoiUtils.closest_requestor_location(req_locations, location)
          qoi = 1.0
          p_a = @priority 
          r_n = requestors.to_f / SPF::Gateway::Service.get_set_max_number_of_requestors(requestors)
          t_rd = SPF::Common::DecayApplier.apply_decay(Time.now - most_recent_request_time, @time_decay_rules)
          d = SPF::Gateway::GPS.new(location, closest_requestor_location).distance
          puts "Distance: #{d}"
          p_rd = SPF::Common::DecayApplier.apply_decay(d, @distance_decay_rules)

          instance_string = case pipeline_id
            when :object_count
              "count objects"
            when :face_recognition
              "count people"
          end

          @requests.delete(pipeline_id)

          # process IO unless we have no requestors
          voi = SPF::Common::VoiUtils.calculate_max_voi(qoi, p_a, r_n, t_rd, p_rd)
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
