require 'java'

module SPF
  module Gateway
    class AudioRecognitionProcessingStrategy
      
      @types = ["MPEG","WAV"]
        
      def initialize
      end
      
      def activate
      end
      
      def deactivate
      end
      
      def interested_in?(raw_data)
        identifier = SPF::Gateway::FileTypeIdentifier.new(raw_data)
        type = identifier.identify
        return @types.find { |e| type =~ Regexp.new(e) }.nil? == false 
      end
      
      #Calculate the Hamming distance between audio streams, in percentage 
      def information_diff(audio1, audio2)
        return exec("python Audio.py "+audio1+" "+audio2)
      end
      
      #Call AcoustID web service for audio identification
      def do_process(audio)
        return exec("python Audio.py "+audio)
      end

    end
  end
end
