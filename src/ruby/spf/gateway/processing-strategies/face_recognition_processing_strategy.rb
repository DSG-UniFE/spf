require 'java'

require_relative './diff'

java_import 'it.unife.spf.FaceRecognition'


module SPF
  module Gateway
    class FaceRecognitionProcessingStrategy

      @@TYPES = ["PNG","TIFF","JPEG","GIF"]
      @@PIPELINE_ID = :face_recognition

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


      def interested_in?(raw_data)
        identifier = SPF::Gateway::FileTypeIdentifier.new(raw_data)
        type = identifier.identify
        return @@TYPES.include?(type)
      end

      #Calculate the difference between input images calling ImageDiff module
      def information_diff(raw_data, last_data)
         return SPF::Gateway::ImageDiff.diff(raw_data, last_data)
      end

      #Do face recognition
      def do_process(raw_data)
         rp = res_path
         return FaceRecognition.doFaceRec(raw_data,rp)
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
