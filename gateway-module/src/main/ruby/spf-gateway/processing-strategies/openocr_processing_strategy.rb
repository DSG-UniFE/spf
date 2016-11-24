require 'java'
require 'ImageDiff'

java_import 'it.unife.spf.TextRecognitionOpenOCR'

module SPF
  module Gateway
    class OpenocrProcessingStrategy
      
      @types = ["PNG","TIFF","JPEG","GIF"]

      
      def initialize
      end
            
      def activate
      end
            
      def deactivate
      end
     
      def interested_in?(raw_data)
        identifier = SPF::Gateway::FileTypeIdentifier.new(raw_data)
        type = identifier.identify
        return @types.find { |e| type =~ Regexp.new(e) }.nil? == false 
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