module SPF
  module Gateway
    class FaceRecognitionProcessingPipeline < Pipeline
      def new_information(raw_data)
        # TODO: da implementare (Marco)
        ImageDiff.diff(raw_data, @last_raw_data_sent)
      end

      def do_process(raw_data)
        # TODO: da implementare (Marco)
      end
    end
  end
end
