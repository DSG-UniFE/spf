require 'chromaprint'
require 'net/http'
require 'waveinfo'

require 'tempfile'
require 'json'


module SPF
  module Gateway
    module Audio

      API_KEY = "HSzCnqXmrz"
      ACOUSTID_URI = 'http://api.acoustid.org/v2/lookup'

      def self.compare(new_stream,old_stream)

       new_data = fix_audio(new_stream)
       old_data = fix_audio(old_stream)

       tmp1 = Tempfile.new('new_data.wav')
       tmp2 = Tempfile.new('old_data.wav')
       tmp1.write(new_data)
       tmp2.write(old_data)
      
       puts "AUDIO COMPARE: "
       wave1 = WaveInfo.new(tmp1.path.to_s)
       wave0 = WaveInfo.new(tmp2.path.to_s) 
        
       dur1 = wave1.duration.to_i
       dur2 = wave2.duration.to_i

       out1 = `fpcalc -ts -chunk #{dur1.to_s} -overlap -json #{tmp1.path.to_s}`
       out2 = `fpcalc -ts -chunk #{dur2.to_s} -overlap -json #{tmp2.path.to_s}`
      
       tmp1.close
       tmp1.unlink
       tmp2.close
       tmp2.unlink

       js1 = JSON.parse(out1)
       js2 = JSON.parse(out2)

       fp1 = js1["fingerprint"].to_s
       fp2 = js2["fingerprint"].to_s

       d = distance(fp1,fp2)

       puts "AUDIO COMPARE RESULT VALUE: #{d.to_s}"
       return d
      end
      
      def self.identify(stream)
        
        audio = fix_audio(stream)
        
        new_tmp = Tempfile.new("audio-stream-fixed.wav")
        new_tmp.write(audio)
        new_tmp.close

        wave = WaveInfo.new(new_tmp.path.to_s)
        duration = wave.duration.to_i
        puts "AUDIO IDENTIFY: #{audio.bytes.to_s.length} bytes, #{duration} sec "
        
        out = `fpcalc -ts -chunk #{duration.to_s} -overlap -json #{new_tmp.path.to_s}`
        js = JSON.parse(out)
        fp = js["fingerprint"].to_s
        puts "New fingerprint: #{fp}"

        new_tmp.unlink

        uri = URI(ACOUSTID_URI)
        res = Net::HTTP.post_form(uri, 'client' => API_KEY, 'duration' => duration.to_i, 'fingerprint' => fp, 'meta' => 'recordings')
        
        puts "AUDIO RESULT: #{res.body}"
        return res.body

      end


      def bad_sequence?(str)
        return !!str.match(/[^ACGT]/i)
      end

      def distance(a,b)

        distance = 0  
        string1, string2 = a.upcase, b.upcase
        puts "error"  if bad_sequence?(string1) || bad_sequence?(string2)
        puts "error2" if string1.length != string2.length

        ary1, ary2 = string1.chars, string2.chars
        ary1.zip(ary2) { |byte1, byte2| distance += 1 unless byte1 == byte2 }
        return distance

      end

      def self.fix_audio(audio)

        chunksize = audio[4,4]
        fmt = audio[8,4]
        #subchunk1size = audio[16,4]
        subchunk2size = audio[40,4]

        new_chunksize_dec = audio.length - 8

        new_chunksize_hex = [new_chunksize_dec].pack("i") 

        audio[4,4] = new_chunksize_hex
        subchunk2size = audio.length - 44
        subchunk2size_hex = [subchunk2size].pack("i")
        audio[40,4] = subchunk2size_hex

        return audio
                
      end

    end
  end
end
