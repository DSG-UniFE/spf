require 'ImageDiff'

java_import 'pipeline.TextRecognitionOpenOCR'

module SPF
  module Gateway
    class OpenocrProcessingPipeline < Pipeline
      
      #Calls ImageDiff module for compute difference between images
      def new_information(raw_data)
        return ImageDiff.diff(raw_data, @last_raw_data_sent)
      end
      
      #Calls java class for compute online-text-recognition
      def do_process(raw_data)
        return TestRecognitionOpenOCR.do(raw_data)
      end
    end
  end
end