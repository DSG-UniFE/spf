require 'java'
require_relative './image_diff'

java_import 'it.unife.spf.TextRecognition'

module SPF
  module Gateway
    class OCRProcessingPipeline

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
       return ImageDiff.calculateDiff(raw_data, last_data)
      end

      #Calls java class for compute local-text-recognition
      def do_process(raw_data)
       return TextRecognition.doOCR(raw_data)
      end

    end
  end
end
