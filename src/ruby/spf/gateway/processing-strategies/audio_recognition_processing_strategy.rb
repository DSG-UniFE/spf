require_relative './audio'


module SPF
  module Gateway
    class AudioRecognitionProcessingStrategy

      @@TYPES = ["WAV"]
      @@PIPELINE_ID = :audio_recognition

      def initialize
        @request_satisfied = false
      end

      def activate
      end

      def deactivate
      end

      def request_satisfied?
        @request_satisfied
      end

      def get_pipeline_id
        @@PIPELINE_ID
      end

      def interested_in?(raw_data, request_hash)
        identifier = SPF::Gateway::FileTypeIdentifier.new(raw_data)
        type = identifier.identify
        type_match = @@TYPES.find { |e| type =~ Regexp.new(e) }.nil? == false

        @request_satisfied = type_match && request_hash.has_key?(@@PIPELINE_ID)
      end

      #Calculate the Hamming distance between audio streams, in percentage
      def information_diff(raw_data, old_data)
        return 1 if old_data.nil?
        puts "called information_diff AudioRecognitionProcessingStrategy"
        return SPF::Gateway::Audio.compare(raw_data, old_data)
      end

      #Call AcoustID web service for audio identification
      def do_process(audio)
        return SPF::Gateway::Audio.identify(audio)
      end

    end
  end
end
