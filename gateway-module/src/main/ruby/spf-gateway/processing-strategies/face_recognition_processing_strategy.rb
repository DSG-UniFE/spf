require 'java'
require_relative './ImageDiff'

java_import 'it.unife.spf.FaceRecognition'

module SPF
  module Gateway
    class FaceRecognitionProcessingStrategy
      
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
      
      #Calculate the difference between input images calling ImageDiff module
      def information_diff(raw_data, last_data)
         return ImageDiff.diff(raw_data, last_data)
      end
      
      #Do face recognition 
      def do_process(raw_data)
         return FaceRecognition.doFaceRec(raw_data)
      end
    end
  end
end
