require 'java'

java_import 'pipeline.ImageDiff'

module SPF
  module Gateway
    module ImageDiff
      
      #Calls java class for compute the difference between images
      def diff(new_data,old_data)
        return ImageDiff.calculateDiff(old_data,new_data)
      
      end
    end
    
  end
end
