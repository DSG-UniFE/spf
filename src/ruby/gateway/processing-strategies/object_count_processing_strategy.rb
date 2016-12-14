require 'java'
require_relative './image_diff'

java_import 'it.unife.spf.CountProcessing'

module SPF
  module Gateway
    class ObjectCountProcessingStrategy

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

      #Calls ImageDiff module for compute the difference between images
      def information_diff(raw_data, last_data)
        return ImageDiff.diff(raw_data, last_data) #return the percentage of difference, ex: 0.92
      end

      #Calls java class for object count
      def do_process(path_image)
          return CountProcessing.CountObject(path_image) #return the number of counted objects, -1 if errors
      end

    end
  end
end
