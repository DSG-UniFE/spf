require 'chromaprint'
require 'net/http'
require 'waveinfo'

module SPF
  module Gateway
    module Audio

      API_KEY = "HSzCnqXmrz"
      ACOUSTID_URI = 'http://api.acoustid.org/v2/lookup'

      def Audio.compare(new_data,old_data)

       wave1 = WaveInfo.new(new_data)
       wave0 = WaveInfo.new(old_data) 
       context1 = Chromaprint::Context.new(wave1.sample_rate.to_i,wave1.channels.to_i)
       context2 = Chromaprint::Context.new(wave0.sample_rate.to_i,wave0.channels.to_i)
       fp1 = context1.get_fingerprint(File.binread(new_data))
       fp2 = context2.get_fingerprint(File.binread(old_data))

       return fp1.compare(fp2)
      
      end

      def Audio.identify(audio)

        wave = WaveInfo.new(audio)
        context = Chromaprint::Context.new(wave.sample_rate.to_i, wave.channels.to_i)
        fp = context.get_fingerprint(File.binread(audio))
        
        duration = wave.duration.to_i
      
        uri = URI(ACOUSTID_URI)
        res = Net::HTTP.post_form(uri, 'client' => API_KEY, 'duration' => duration, 'fingerprint' => fp.compressed, 'meta' => 'recordings')
        
        #For debug
        puts "Audio match : #{res.body}" 
        return res.body
      
      end

    end
  end
end