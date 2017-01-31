require_relative './audio'


module SPF
  module Gateway
    class AudioRecognitionProcessingStrategy
      
      @@TYPES = ["WAV"]
      @@PIPELINE_ID = :audio_recognition

      def initialize
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

      #Calculate the Hamming distance between audio streams, in percentage
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
