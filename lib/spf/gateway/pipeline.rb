module SPF
  module Gateway
    class Pipeline
      ##################################################
      # MUST BE THREAD SAFE!!!!
      ##################################################

      def initialize(threshold)
        @processing_threshold = threshold.try(:to_f)
        raise ArgumentError unless @processing_threshold

        @last_raw_data_sent = nil
        # keep_going needs to be atomic
        @keep_going = Concurrent::AtomicBoolean.... # TODO
      end

      def activate
        @keep_going = true
      end

      def deactivate
        @keep_going = false
      end

      def process(raw_data)
        # calculate amount of new information with respect to previous messages
        delta = new_information(raw_data)

        # ensure that the delta passes the processing threshold
        return nil if delta < @processing_threshold

        # update last_raw_data_sent
        @last_raw_data_sent = raw_data

        # process raw_data
        do_process(raw_data)
      end

      # percentage of difference between raw_data and @last_raw_data_sent
      def new_information(raw_data)
        raise "Need to implement it in subclass."
      end

      # actual processing
      def do_process(raw_data)
        raise "Need to implement it in subclass."
      end
    end
  end
end
