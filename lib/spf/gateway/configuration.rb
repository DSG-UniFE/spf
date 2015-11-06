require 'spf/support/dsl_helper'

require 'ice_nine'
require 'ice_nine/core_ext/object'


module SPF
  module Gateway

    module Configurable
      dsl_accessor :find,
                   :listen,
                   :count_objects,
                   :track_objects
    end

    class Configuration
      include Configurable

      attr_accessor :filename

      def find
        ...
      end

      def listen
        ...
      end

      def validate
        # freeze everything!
        @start_time.deep_freeze
        @duration.deep_freeze
        @warmup_duration.deep_freeze
        @incident_generation.deep_freeze
        @transition_matrix.deep_freeze
        @cost_analysis.deep_freeze
        @support_groups.deep_freeze
      end

    end

  end
end
