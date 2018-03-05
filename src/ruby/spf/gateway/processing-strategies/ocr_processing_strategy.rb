require 'java'

require 'spf/gateway/file_type_identifier'

require_relative './diff'
require_relative './basic_processing_strategy'

java_import 'it.unife.spf.TextRecognition'


module SPF
  module Gateway
    class OcrProcessingStrategy < SPF::Gateway::BasicProcessingStrategy

      def initialize
        super(["PNG","TIFF","JPEG","GIF"], :ocr, self.class.name)
      end

      # Calls ImageDiff module for compute difference between images
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
