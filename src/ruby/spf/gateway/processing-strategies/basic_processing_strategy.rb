module SPF
  module Gateway
    class BasicProcessingStrategy

      attr_reader :types, :pipeline_id

      def initialize(types, pipeline_id, parent_class_name)
        @parent_class_name = parent_class_name
        @types = types
        @pipeline_id = pipeline_id
      end

      def get_pipeline_id
        @pipeline_id
      end

      def activate
      end

      def deactivate
      end

      def interested_in?(type)
        @types.include?(type)
      end

      def information_diff(raw_data, old_data)
        raise "*** #{BasicProcessingStrategy.name} < #{@parent_class_name}: Parent class needs to implement the information_diff method! ***"
      end

      def do_process(raw_data)
        raise "*** #{BasicProcessingStrategy.name} < #{@parent_class_name}: Parent class needs to implement the do_process method! ***"
      end

    end
  end
end
