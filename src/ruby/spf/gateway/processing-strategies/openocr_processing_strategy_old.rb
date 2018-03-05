require 'java'

require_relative './diff'
require_relative './basic_processing_strategy'

java_import 'it.unife.spf.TextRecognitionOpenOCR'


module SPF
  module Gateway
    class OpenocrProcessingStrategy < SPF::Gateway::BasicProcessingStrategy

      def initialize
        super(["PNG","TIFF","JPEG","GIF"], :open_ocr, self.class.name)
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
