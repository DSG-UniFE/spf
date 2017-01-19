require_relative './audio'
require 'colorize'

module SPF
  module Gateway
    class AudioRecognitionProcessingStrategy

      @@TYPES = ["WAV"]

      def initialize
      end

      def activate
      end

      def deactivate
      end

      def interested_in?(raw_data)
        identifier = SPF::Gateway::FileTypeIdentifier.new(raw_data)
        type = identifier.identify
        return @@TYPES.find { |e| type =~ Regexp.new(e) }.nil? == false
      end

      #Calculate the Hamming distance between audio streams, in percentage
      def information_diff(raw_data, old_data)
        return 1 if old_data.nil?
        puts "called information_diff AudioRecognitionProcessingStrategy".yellow
        return SPF::Gateway::Audio.compare(raw_data, old_data)
      end

      #Call AcoustID web service for audio identification
      def do_process(audio)
        return SPF::Gateway::Audio.identify(audio)
      end

    end
  end
end
