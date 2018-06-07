require_relative './audio'
require_relative './basic_processing_strategy'

module SPF
  module Gateway
    class AudioRecognitionProcessingStrategy < SPF::Gateway::BasicProcessingStrategy

      def initialize
        super(["WAV"], :audio_recognition, self.class.name)
      end

      # Calculate the Hamming distance between audio streams, in percentage
      def information_diff(raw_data, old_data)
        return 1 if old_data.nil?
        SPF::Gateway::Audio.compare(raw_data, old_data)
      end

      #Call AcoustID web service for audio identification
      def do_process(audio)
        SPF::Gateway::Audio.identify(audio)
      end

    end
  end
end
