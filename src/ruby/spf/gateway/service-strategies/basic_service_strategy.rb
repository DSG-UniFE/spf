require 'java'
require 'matrix'

require 'spf/common/exceptions'
require 'spf/common/decay_applier'
require 'spf/common/voi_utils'
require 'spf/gateway/pig'
require 'spf/gateway/service'


module SPF
  module Gateway
    class BasicServiceStrategy

      include SPF::Common::VoiUtils
      include SPF::Common::DecayApplier

      @@DEFAULT_TIME_DECAY = {
        type: :linear,
        max: 5.minutes
      }
      @@DEFAULT_DISTANCE_DECAY = {
        type: :linear,
        max: 1.km
      }


      def initialize(priority, pipeline_names, time_decay_rules=@@DEFAULT_TIME_DECAY, distance_decay_rules=@@DEFAULT_DISTANCE_DECAY, parent_class_name)
        @priority = priority
        @pipeline_names = pipeline_names
        @time_decay_rules = time_decay_rules.nil? || time_decay_rules[:type].nil? || time_decay_rules[:max].nil? ? @@DEFAULT_TIME_DECAY.dup.freeze : time_decay_rules.dup.freeze
        @distance_decay_rules = distance_decay_rules.nil? || distance_decay_rules[:type].nil? || distance_decay_rules[:max].nil? ? @@DEFAULT_DISTANCE_DECAY.dup.freeze : distance_decay_rules.dup.freeze
        @requests = {}
        @content_type = "text/plain"
        @parent_class_name = parent_class_name
      end

      def add_request(user_id, req_loc, req_string)
        raise "*** #{BasicServiceStrategy.name} < #{@parent_class_name}: Parent class needs to implement the add_request method! ***"
      end

      def has_requests_for_pipeline(pipeline_id)
        @requests.has_key?(pipeline_id)
      end

      def execute_service(io, source, pipeline_id)
        raise "*** #{BasicServiceStrategy.name} < #{@parent_class_name}: Parent class needs to implement the execute_service method! ***"
      end

      def content_type
        @content_type
      end


      private

        def remove_expired_requests(requests, expiration_time)
          now = Time.now
          requests.delete_if { |req| req[2] + expiration_time < now }
        end

    end
  end
end
