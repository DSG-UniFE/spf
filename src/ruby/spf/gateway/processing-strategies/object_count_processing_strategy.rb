require 'java'

require_relative './diff'

java_import 'it.unife.spf.CountProcessing'


module SPF
  module Gateway
    class ObjectCountProcessingStrategy

      @@TYPES = ["PNG","TIFF","JPEG","GIF"]
      @@PIPELINE_ID = :object_count

      def initialize
      end

      def activate
      end

      def deactivate
      end

      def request_satisfied?
        false
      end

      def get_pipeline_id
        @@PIPELINE_ID
      end

      def interested_in?(raw_data, request_hash)
        identifier = SPF::Gateway::FileTypeIdentifier.new(raw_data)
        type = identifier.identify
        return @@TYPES.include?(type)
      end

      #Calls ImageDiff module for compute the difference between images
      def information_diff(raw_data, last_data)
        return SPF::Gateway::ImageDiff.diff(raw_data, last_data) #return the percentage of difference, ex: 0.92
      end

      #Calls java class for object count
      def do_process(path_image)
          rp = res_path
          return CountProcessing.CountObject(path_image, rp) #return the number of counted objects, -1 if errors
      end

      private

        def res_path
           abs = File.absolute_path(__FILE__)
           arr = abs.split("/")
           arr.pop(5)
           pt = arr.join("/")
           pt1 = File.join(pt, "resources","images")
           return pt1
        end

    end
  end
end
