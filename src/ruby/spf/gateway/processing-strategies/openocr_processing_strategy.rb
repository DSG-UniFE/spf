require 'java'

require_relative './diff'

java_import 'it.unife.spf.TextRecognitionOpenOCR'


module SPF
  module Gateway
    class OpenocrProcessingStrategy

      @@TYPES = ["PNG","TIFF","JPEG","GIF"]
      @@PIPELINE_ID = :openocr

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
        type = SPF::Gateway::FileTypeIdentifier.identify(raw_data)
        @@TYPES.include?(type)
      end

      #Calls ImageDiff module for compute difference between images
      def information_diff(raw_data, last_data)
        SPF::Gateway::ImageDiff.diff(raw_data, last_data)
      end

      #Calls java class for compute online-text-recognition
      def do_process(raw_data)
        TestRecognitionOpenOCR.doOCR
      end

    end
  end
end
