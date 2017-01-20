require "net/http"
require "uri"
require "timeout"

require 'spf/common/logger'
require 'spf/common/exceptions'


module SPF
  module Gateway
    class IpCameraInterface

      include SPF::Logging
      
      def self.request_photo(ip, port)
        uri = URI.parse("http://#{ip.to_s}/photo.jpg")
        uri.port = port

        begin
          http = Net::HTTP.new(uri.host, uri.port)
          request = Net::HTTP::Get.new(uri.request_uri)
          http.request(request).body
        rescue Net::OpenTimeout => e
          logger.warn "*** #{self.class.name}: Timeout expired trying to connect to #{ip}:#{port}: #{e.message} ***"
        rescue SocketError, Errno::ECONNREFUSED
          logger.warn "*** #{self.class.name}: Impossible to connect to #{ip}:#{port}: #{e.message} ***"
        rescue => e
          logger.error "*** #{self.class.name}: Unexpected error trying to connect to #{ip}:#{port}: #{e.message} ***"
        end
      end

      def self.request_audio(ip, port, duration)
        uri = URI.parse("http://#{ip.to_s}/audio.wav")
        uri.port = port
        audio = ""

        begin
          Net::HTTP.start(uri.host, uri.port) do |http|
            request = Net::HTTP::Get.new(uri.request_uri)
            Timeout.timeout(duration) do 
              http.request(request) do |audio_response|
                audio_response.read_body do |chunk|
                  audio << chunk
                end
              end
            end
          end
        rescue Net::OpenTimeout => e
          logger.warn "*** #{self.class.name}: Timeout expired trying to connect to #{ip}:#{port}: #{e.message} ***"
        rescue SocketError, Errno::ECONNREFUSED
          logger.warn "*** #{self.class.name}: Impossible to connect to #{ip}:#{port}: #{e.message} ***"
        rescue => e
          logger.error "*** #{self.class.name}: Unexpected error trying to connect to #{ip}:#{port}: #{e.message} ***"
        end

        #puts "Readed #{@audio.length.to_i} bytes of audio"
        audio
      end

      def self.request_video(ip, port, duration)
        uri = URI.parse("http://#{ip.to_s}/video")
        uri.port = port
        video = ""

        Net::HTTP.start(uri.host, uri.port) do |http|
          request = Net::HTTP::Get.new(uri.request_uri)
          begin
            Timeout.timeout(duration) do 
              http.request(request) do |video_response|
                video_response.read_body do |chunk|
                  video << chunk
                end
              end
            end
          rescue Net::OpenTimeout => e
            logger.warn "*** #{self.class.name}: Timeout expired trying to connect to #{ip}:#{port}: #{e.message} ***"
          rescue SocketError, Errno::ECONNREFUSED
            logger.warn "*** #{self.class.name}: Impossible to connect to #{ip}:#{port}: #{e.message} ***"
          rescue => e
            logger.error "*** #{self.class.name}: Unexpected error trying to connect to #{ip}:#{port}: #{e.message} ***"
          end
        end

        #puts "Readed #{@video.length.to_i} bytes of video"
        video
      end
      
      
      private
      
        def initialize()
        end
        
    end
  end
end