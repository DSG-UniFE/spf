require 'chromaprint'
require 'net/http'
require 'waveinfo'
require 'tempfile'


module SPF
  module Gateway
    module Audio

      API_KEY = "HSzCnqXmrz"
      ACOUSTID_URI = 'http://api.acoustid.org/v2/lookup'

      def Audio.compare(new_data,old_data)

       tmp1 = Tempfile.new('new_data.wav')
       tmp2 = Tempfile.new('old_data.wav')
       tmp2.write(new_data)
       tmp2.write(old_data)
       file1 = File.open(tmp1.path.to_s)
       file2 = File.open(tmp2.path.to_s)

       puts "AUDIO_COMPARE CALLED"
       wave1 = WaveInfo.new(file1)
       wave0 = WaveInfo.new(file2)
       context1 = Chromaprint::Context.new(wave1.sample_rate.to_i,wave1.channels.to_i)
       context2 = Chromaprint::Context.new(wave0.sample_rate.to_i,wave0.channels.to_i)
       fp1 = context1.get_fingerprint(File.binread(new_data))
       fp2 = context2.get_fingerprint(File.binread(old_data))
       a = fp1.compare(fp2)

       tmp1.close
       tmp1.unlink
       tmp2.close
       tmp2.unlink

       puts "AUDIO DIFFERENCE VALUE : #{a}"
       return a
      end

      def Audio.identify(audio)
        puts "IDENTIFY: #{audio.bytes.to_s.length}"
        tmp = Tempfile.new('audioidentify.wav')
        tmp.write(audio)
        file = File.open(tmp.path.to_s)
        wave = WaveInfo.new(file)
        context = Chromaprint::Context.new(wave.sample_rate.to_i, wave.channels.to_i)
        fp = context.get_fingerprint(File.binread(audio))

        bps = wave.bits_per_sample / 8
        samples = audio.lentgh / bps
        duration = samples.to_f / wave.sample_rate.to_f
        duration = duration.round.to_i

        uri = URI(ACOUSTID_URI)
        res = Net::HTTP.post_form(uri, 'client' => API_KEY, 'duration' => duration, 'fingerprint' => fp.compressed, 'meta' => 'recordings')

        #For debug
        puts "Audio match : #{res.body}"
        return res.body

      end

    end
  end
end
