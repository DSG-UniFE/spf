require 'socket'
require 'concurrent'
require 'spf/common/logger'
require 'spf/gateway/ip_camera_interface'

module SPF
  module Gateway
    class DataRequestor

      include SPF::Logging

      def initialize(cameras, service_manager)
        
        @cams = cameras
        @service_manager = service_manager
        @pool = Concurrent::CachedThreadPool.new
      
      end

      def run
        logger.info "*** Pig: Starting Data Requestor ***"
        @random_sleep = Random.new
        @random_type = Random.new

        loop do
          raw_data = ""
          type = @random_type.rand(2)
          case type
            when 0 then raw_data, source = request_photo
            when 1 then raw_data, source = request_audio
            else raise "Problem in random number"
          end
        
        end

      end

      def request_photo

        @cams.each do |cam|

          ipcam = SPF::Gateway::IpCameraInterface.new(cam[:ip], cam[:port].to_i)
          logger.info "*** Pig: Requested photo from #{cam[:name]}:#{cam[:ip]} ***"
          image = ipcam.request_photo
          send_to_pipelines(image, cam[:ip])
          logger.info "*** Sending #{image.length} bytes of image to interested pipelines ***"
          sleep(@random_sleep.rand(4))
        end

      end

      def request_audio

        @cams.each do |cam|

          ipcam = SPF::Gateway::IpCameraInterface.new(cam[:ip], cam[:port].to_i)
          logger.info "*** Pig: Requested audio from #{cam[:name]}:#{cam[:ip]} ***"
          audio = ipcam.request_audio(cam[:duration].to_i)
          send_to_pipelines(audio, cam[:ip])
          logger.info "*** Sending #{audio.length} bytes, #{cam[:duration].to_i}s of audio to interested pipelines ***"
          sleep(@random_sleep.rand(4))
        end
      end

      def send_to_pipelines(raw_data, source)

        @service_manager.with_pipelines_interested_in(raw_data) do |pl|
            @pool.post do
              begin
              pl.process(raw_data, source)
              rescue => e
                puts e.message
                puts e.backtrace
                raise e
              end
            end
          end
      end
    end
  end
end
