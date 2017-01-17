require "net/http"
require "uri"
require "timeout"
require 'spf/common/exceptions'

module SPF
  module Gateway

    class IpCameraInterface

      def initialize(ip,port)
        
        @ip = ip
        @port = port.to_i

      end 

      def request_photo()
                
        uri = URI.parse("http://#{@ip.to_s}/photo.jpg")
        uri.port = @port
        
          http = Net::HTTP.new(uri.host, uri.port)
          request = Net::HTTP::Get.new(uri.request_uri)
          @img_response = http.request(request)
        
          # To write the binary image file:
          # File.open("/home/marco/Scrivania/ip_camera_image.jpg", "wb") do |f|
          #  f.write(img_response.body)
          # end
          #puts "Readed #{@img_response.body.length.to_i} bytes of image"
          return @img_response.body
        
      end

      def request_audio(time)
        
        duration = time.to_i
        uri = URI.parse("http://#{@ip.to_s}/audio.wav")
        uri.port = @port
        @audio = ""

        Net::HTTP.start(uri.host, uri.port) do |http|
            request = Net::HTTP::Get.new(uri.request_uri)

            begin
            Timeout.timeout(duration) do 
              http.request(request) do |audio_response|
                  audio_response.read_body do |chunk|
                    @audio << chunk
                  end

              end
            end
            rescue Timeout::Error
            end

            # FOR WRITE AUDIO ON DISK
            # File.open("/home/marco/Scrivania/ip_camera_audio.wav", "wb") do |f|
            #   f.write(@audio)
            # end
            
        end

        #puts "Readed #{@audio.length.to_i} bytes of audio"
        return @audio
      end


      def request_video(time)
          
        duration = time.to_i
        uri = URI.parse("http://#{@ip.to_s}/video")
        uri.port = @port
        @video = ""

        Net::HTTP.start(uri.host, uri.port) do |http|
            request = Net::HTTP::Get.new(uri.request_uri)

            begin
            Timeout.timeout(duration) do 
              http.request(request) do |video_response|
                  video_response.read_body do |chunk|
                    @video << chunk
                  end

              end
            end
            rescue Timeout::Error
            end

            #FOR WRITE VIDEO ON DISK
            File.open("/home/marco/Scrivania/ip_camera_video.mjpg", "wb") do |f|
              f.write(@video)
            end
            
        end

        puts "Readed #{@video.length.to_i} bytes of video"
        return @video


      end
    end
  end
end