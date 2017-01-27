require 'java'

require 'spf/gateway/file_type_identifier'

require_relative './diff'

java_import 'it.unife.spf.TextRecognition'


module SPF
  module Gateway
    class OCRProcessingStrategy

      @@TYPES = ["PNG","TIFF","JPEG","GIF"]
      @@PIPELINE_ID = :ocr

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
        SPF::Gateway::Diff.diff(raw_data, last_data)
      end

      #Calls java class for compute local-text-recognition
      def do_process(raw_data)
        TextRecognition.doOCR(raw_data.to_java_bytes)
      end

    end
  end
end
