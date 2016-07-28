
require 'ImageDiff'

java_import 'pipeline.FaceRecognition'

module SPF
  module Gateway
    class FaceRecognitionProcessingPipeline < Pipeline
      
      #Calculate the difference between input images calling ImageDiff module
      def new_information(raw_data)
         return ImageDiff.diff(raw_data, @last_raw_data_sent)
      end
      
      #Do face recognition 
      def do_process(raw_data)
         return FaceRecognition.doFaceRec(raw_data)
      end
    end
  end
end
