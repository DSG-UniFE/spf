require 'java'

require 'spf/gateway/file_type_identifier'

require_relative './diff'
require_relative './basic_processing_strategy'

java_import 'it.unife.spf.CountProcessing'


module SPF
  module Gateway
    class ObjectCountProcessingStrategy < SPF::Gateway::BasicProcessingStrategy

      def initialize
        super(["PNG","TIFF","JPEG","GIF"], :object_count, self.class.name)
      end

      # Calls ImageDiff module for compute the difference between images
      def information_diff(raw_data, last_data)
        SPF::Gateway::Diff.diff(raw_data, last_data) #return the percentage of difference, ex: 0.92
      end

      # Calls java class for object count
      def do_process(raw_data)
        rp = res_path
        CountProcessing.CountObject(raw_data.to_java_bytes, rp) #return the number of counted objects, -1 if errors
      end


      private

        def res_path
          abs = File.absolute_path(__FILE__)
          arr = abs.split("/")
          arr.pop(6)
          pt = arr.join("/")
          pt1 = File.join(pt, "resources","images")
          return pt1
        end

    end
  end
end
