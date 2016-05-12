module SPF
  module Gateway
    class Service
      def initialize(app)
        @application = app
        @channel = channel
        @closest_recipient = nil
        @most_recent_request = nil
      end

      def register_requestor(user)
        # TODO: update closest_recipient
      end

      def unregister_requestor(user)
        # TODO: update closest_recipient
      end

      def new_data(raw_data)
        # do the actual processing
        io = @processing_pipeline.process(raw_data) # services might share pipelines

        # if raw_data was not different enough from previously processed
        # raw_data, it won't be processed
        next unless io

        # calculate voi
        voi = calculate_max_voi(io)

        # disseminate...
        # call DisService
        disseminate(io, voi, @channel)
      end

      # TODO: implement VoI calculation
      def calculate_max_voi
        # TODO: TRADURRE ROBA LUCA IN RUBY
      end
    end
  end
end
