require 'ImageDiff'

java_import 'pipeline.Count_Processing'

module SPF
  module Gateway
    class ObjectCountProcessingPipeline < Pipeline
       
      #Calls ImageDiff module for compute the difference between images
      def new_information(raw_data)
        return ImageDiff.diff(raw_data, @last_raw_data_sent) #return the percentage of difference, ex: 0.92
      end
      
      #Calls java class for object count
      def do_process(path_image)
          return Count_Processing.CountObject(path_image) #return the number of counted objects, -1 if errors
      end
      
    end
  end
end
