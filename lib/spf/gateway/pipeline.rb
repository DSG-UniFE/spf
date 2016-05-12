module SPF
  module Gateway
    class Pipeline
      ##################################################
      # MUST BE THREAD SAFE!!!!
      ##################################################

      def initialize()
        @last_raw_data_sent = nil
        # keep_going needs to be atomic
        @keep_going = ...
      end

      # lancia un thread pool
      def activate
        @keep_going = true
      end

      # stop
      def deactivate
        @keep_going = false
      end

      def handle_request(raw_data)
        # calculate amount of new information with respect to previous messages
        delta = new_information(raw_data)

        # ensure that the delta passes the processing threshold
        if delta > @processing_threshold
          # update last_raw_data_sent
          @last_raw_data_sent = raw_data

          # process raw_data
          process(raw_data) # classi java implementate da gentilini
        end
      end

      private

        # TODO: percentage of difference between raw_data and @last_raw_data_sent
        def new_information(raw_data)

        end
    end
  end
end
