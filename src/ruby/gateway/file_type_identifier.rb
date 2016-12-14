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

      def initialize(file)
        @file = file
      end

      def identify
        data = ''
        #reference to specified file
        s = open(@file, 'rb')

        #reading only first "line" for each file
        i=0
        s.each_line do |line|
          data += line
          if i > 1 then
            break
          end
          i+=1
        end

        #decode binary string into hexadecimal string, return an array with the decoded string
        arr = data.unpack('H*')

        #get the decoded string
        str = arr[0]

        #get first 3 bytes
        header = str[0..5]

        #identify filetype
        type = case header
          when "ffd8ff" then "JPEG"
          when "89504e" then "PNG"
          when "474946" then "GIF"
          when "49492a" then "TIFF"
          when "4d4d00" then "TIFF"
          when "524946" then "WAV"
          when "494433" then "MPEG"
        end

        return type.to_s
      end

    end
  end
end



