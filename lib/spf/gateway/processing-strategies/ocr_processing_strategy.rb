require 'ImageDiff'

java_import 'pipeline.TextRecognition'


module SPF
  module Gateway
    class OCRProcessingPipeline < Pipeline
      
      def initialize
      end
      
      def activate
      end
      
      def deactivate
      end
      
        #Calls ImageDiff module for compute difference between images
      def new_information(raw_data,last_data)
       return ImageDiff.calculateDiff(raw_data, last_data)
      end
      
      #Calls java class for compute local-text-recognition
      def do_process(raw_data)
       return TextRecognition.doOCR(raw_data)
      end
    end
  end
end
