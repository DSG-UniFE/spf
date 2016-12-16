require 'chromaprint'
require 'net/http'
require 'audioinfo'

module SPF
  module Gateway
    module Audio

      API_KEY = "HSzCnqXmrz"
      DEFAULT_DURATION = 200
      ACOUSTID_URI = 'http://api.acoustid.org/v2/lookup'

      def Audio.compare(new_data,old_data)
       context1 = Chromaprint::Context.new(44100, 1)
       context2 = Chromaprint::Context.new(44100, 1)
       fp1 = context1.get_fingerprint(File.binread(new_data))
       fp2 = context2.get_fingerprint(File.binread(old_data))
       return fp1.compare(fp2)
      end

      def Audio.identify(audio)
        duration = DEFAULT_DURATION

        AudioInfo.open(audio) do |info|
          info.artist   # or info["artist"]
          info.title    # or info["title"]
          duration = info.length   # playing time of the file
          info.bitrate  # average bitrate
          info.to_h     # { "artist" => "artist", "title" => "title", etc... }
        end

        context = Chromaprint::Context.new(44100, 1)
        fp = context.get_fingerprint(File.binread(audio))
        uri = URI(ACOUSTID_URI)
        res = Net::HTTP.post_form(uri, 'client' => API_KEY, 'duration' => duration, 'fingerprint' => fp.compressed)

        return res.body
      end

    end
  end
end
