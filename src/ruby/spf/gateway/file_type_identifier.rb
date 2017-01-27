module SPF
  module Gateway

    class FileTypeIdentifier

      def self.identify(raw_data)
        header = raw_data[0,3].unpack('H*')
        type = case header.join("")
          when "ffd8ff" then "JPEG"
          when "89504e" then "PNG"
          when "474946" then "GIF"
          when "49492a" then "TIFF"
          when "4d4d00" then "TIFF"
          when "524946" then "WAV"
          when "494433" then "MPEG"
          else "NOT_MATCH"
        end

        type
      end

    end
  end
end



