require 'ImageDiff'

java_import 'pipeline.TextRecognitionOpenOCR'

module SPF
  module Gateway
    class OpenocrProcessingStrategy
      
      def initialize
      end
            
      def activate
      end
            
      def deactivate
      end
           
      #Calls ImageDiff module for compute difference between images
      def information_diff(raw_data, last_data)
        return ImageDiff.diff(raw_data, last_data)
      end
      
      #Calls java class for compute online-text-recognition
      def do_process(raw_data)
        return TestRecognitionOpenOCR.doOCR
      end
    end
  end
end