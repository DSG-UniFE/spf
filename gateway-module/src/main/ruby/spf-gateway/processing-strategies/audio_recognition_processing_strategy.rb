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
        return SPF::Gateway::Audio.compare(audio1, audio2)
      end
      
      #Call AcoustID web service for audio identification
      def do_process(audio)
        return SPF::Gateway::Audio.identify(audio)
      end

    end
  end
end
