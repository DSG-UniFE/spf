require 'socket'
require 'concurrent'

require 'spf/common/logger'
require 'spf/gateway/ip_camera_interface'


module SPF
  module Gateway
    class DataRequestor

      include SPF::Logging

      def initialize(cameras, service_manager, benchmark)
        @cams = cameras
        @service_manager = service_manager
        @pool = Concurrent::CachedThreadPool.new
        @benchmark = benchmark
      end

      def run
        logger.info "*** #{self.class.name}: Starting Data Requestor ***"
        @random_sleep = Random.new
        @random_type = Random.new

        loop do
          raw_data = ""
          type = @random_type.rand(1)
          case type
            when 0 then raw_data, source = request_photo
            when 1 then raw_data, source = request_audio
            else raise "#{self.class.name}: Problem in random number"
          end
          sleep @random_sleep.rand(5)
        end
      end


      private

        def request_photo
          @cams.each do |cam|
            logger.info "*** #{self.class.name}: Requesting photo from sensor #{cam[:name]} (#{cam[:ip]}:#{cam[:port]}) ***"
            image = IpCameraInterface.request_photo(cam[:ip], cam[:port])
            send_to_pipelines(image, cam[:cam_id], cam[:source]) unless image.nil?
          end
        end

        def request_audio
          @cams.each do |cam|
            logger.info "*** #{self.class.name}: Requesting audio from sensor #{cam[:name]} (#{cam[:ip]}:#{cam[:port]}) ***"
            audio = IpCameraInterface.request_audio(cam[:ip], cam[:port], cam[:duration])
            send_to_pipelines(audio, cam[:cam_id], cam[:source]) unless audio.nil?
          end
        end

        def send_to_pipelines(raw_data, cam_id, source)
          @service_manager.with_pipelines_interested_in(raw_data) do |pl|
            @pool.post do
              begin
                logger.info "*** #{self.class.name}: #{pl} is processing #{raw_data.length} bytes from #{source.to_s} ***"

                bench = pl.process(raw_data, cam_id.to_s, source)
                  unless bench.nil? or bench.empty?
                    @benchmark << bench
                  end
              rescue => e
                logger.error "*** #{self.class.name}: unexpected error, #{e.message} ***"
                logger.error e.backtrace
              end
            end
          end
        end

    end
  end
end
