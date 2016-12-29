module SPF
  module Gateway

    ### USAGE ###

    # fileId = SPF::Gateway::FileTypeIdentifier.new('<my-file>')
    # type = fileId.identify()
    # puts type
    # => <filetype>

    ### NOTES ###

    #Supports most popular images and audio format

    class FileTypeIdentifier

      attr_reader :file

      def initialize(raw_data)
        @raw_data = raw_data
      end

      def identify
        header = @raw_data[0,3].unpack('H*')
        #identify filetype
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

        return type.to_s
      end

    end
  end
end



