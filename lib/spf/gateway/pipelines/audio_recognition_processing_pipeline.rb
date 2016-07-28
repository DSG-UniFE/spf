require 'java'

java_import 'pipeline.AudioDiff'


module SPF
  module Gateway
    class AudioRecognitionProcessingPipeline < Pipeline
      
      #Calculate the Hamming distance between audio streams, in percentage 
      def new_information(audio1,audio2)
        return exec("python AudioDiff.py "+audio1+" "+audio2)
      end
      
      #Call AcoustID web service for audio identification
      def do_process(audio)
        return exec("python AudioIdentification.py "+audio)
      end

    end
  end
end
