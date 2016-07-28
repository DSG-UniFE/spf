require 'ImageDiff'

java_import 'pipeline.TextRecognition'


module SPF
  module Gateway
    class OCRProcessingPipeline < Pipeline
      
        #Calls ImageDiff module for compute difference between images
      def new_information(raw_data)
       return ImageDiff.diff(raw_data, @last_raw_data_sent)
      end
      
      #Calls java class for compute local-text-recognition
      def do_process(raw_data)
       #TO DO 
      end
    end
  end
end
