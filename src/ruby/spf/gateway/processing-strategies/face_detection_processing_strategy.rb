require 'java'

require 'spf/gateway/file_type_identifier'

require_relative './diff'
require_relative './basic_processing_strategy'

java_import 'it.unife.spf.FaceDetection'


module SPF
  module Gateway
    class FaceDetectionProcessingStrategy < SPF::Gateway::BasicProcessingStrategy

      def initialize
        super(["PNG","TIFF","JPEG","GIF"], :face_detection, self.class.name)
        @rp = res_path
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
