require 'java'

require 'spf/gateway/file_type_identifier'

require_relative './diff'

java_import 'it.unife.spf.FaceDetection'


module SPF
  module Gateway
    class FaceDetectionProcessingStrategy

      @@TYPES = ["PNG","TIFF","JPEG","GIF"]
      @@PIPELINE_ID = :face_detection

      def initialize
        @rp = res_path
      end

      def get_pipeline_id
        @@PIPELINE_ID
      end

      def activate
      end

      def deactivate
      end

      def interested_in?(type)
        @@TYPES.include?(type)
      end

      # Calculate the difference between input images calling ImageDiff module
      def information_diff(raw_data, last_data)
        SPF::Gateway::Diff.diff(raw_data, last_data)
      end

      # Do face detection
      def do_process(raw_data)
        FaceRecogntion.doFaceDet(raw_data.to_java_bytes, @rp)
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
