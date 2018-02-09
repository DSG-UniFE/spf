require "net/http"
require "uri"
require "timeout"

require 'spf/common/logger'
require 'spf/common/exceptions'


module SPF
  module Gateway
    class IpCameraInterface

      include SPF::Logging
      
      def self.request_photo(url)
        uri = URI.parse(url)
        begin
          http = Net::HTTP.new(uri.host, uri.port)
          request = Net::HTTP::Get.new(uri.request_uri)
          return http.request(request).body
        rescue Net::OpenTimeout => e
          logger.warn "*** #{self.name}: Timeout expired trying to connect to #{url}: #{e.message} ***"
        rescue SocketError, Errno::ECONNREFUSED => e
          logger.warn "*** #{self.name}: Impossible to connect to #{url}: #{e.message} ***"
        rescue => e
          logger.error "*** #{self.name}: Unexpected error trying to connect to #{url}: #{e.message} ***"
        end

        nil
      end

      def self.request_audio(url)
        uri = URI.parse(url)
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
        
          return audio
        rescue Timeout::Error => e
          logger.info "*** #{self.name}: Sampling audio completed from #{url} ***"
          return audio
        rescue Net::OpenTimeout => e
          logger.warn "*** #{self.name}: Timeout expired trying to connect to #{url}: #{e.message} ***"
        rescue SocketError, Errno::ECONNREFUSED => e
          logger.warn "*** #{self.name}: Impossible to connect to #{url}: #{e.message} ***"
        rescue => e
          logger.error "*** #{self.name}: Unexpected error trying to connect to #{url}: #{e.message} ***"
        end

        nil
      end

      def self.request_video(url, duration)
        uri = URI.parse(url)
        video = ""

        begin
          Net::HTTP.start(uri.host, uri.port) do |http|
            request = Net::HTTP::Get.new(uri.request_uri)
            Timeout.timeout(duration) do 
              http.request(request) do |video_response|
                video_response.read_body do |chunk|
                  video << chunk
                end
              end
            end
          end
            
          return video
        rescue Net::OpenTimeout => e
          logger.warn "*** #{self.name}: Timeout expired trying to connect to #{url}: #{e.message} ***"
        rescue SocketError, Errno::ECONNREFUSED => e
          logger.warn "*** #{self.name}: Impossible to connect to #{url}: #{e.message} ***"
        rescue => e
          logger.error "*** #{self.name}: Unexpected error trying to connect to #{url}: #{e.message} ***"
        end
            
        nil
      end
      
      
      private
      
        def initialize()
        end
        
    end
  end
end
