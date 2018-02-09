require 'socket'
require 'concurrent'

require 'spf/common/logger'
require 'spf/gateway/ip_camera_interface'


module SPF
  module Gateway
    class DataRequestor

      include SPF::Logging

      @@DEFAULT_SLEEP_TIME = 30
      @@DEFAULT_SERVICE_DURATION = 30000

      def initialize(cameras, service_manager, benchmark)
        @cams = cameras
        @service_manager = service_manager
        @pool = Concurrent::CachedThreadPool.new
        @benchmark = benchmark
      end

      def run
        logger.info "*** #{self.class.name}: Starting Data Requestor ***"
        #request raw data from each camera
        loop do
          request_photo
          sleep @@DEFAULT_SLEEP_TIME
        end
      end


      private

        def request_photo
          # delete expired cameras
          @cams.delete_if { |cam| cam[:activation_time] + @@DEFAULT_SERVICE_DURATION < Time.now }

          @cams.each do |cam|
            logger.info "*** #{self.class.name}: Requesting photo from sensor #{cam[:name]} (#{cam[:url]}) ***"
            image = IpCameraInterface.request_photo(cam[:url])
            send_to_pipelines(image, cam[:cam_id], cam[:source]) unless image.nil?
          end
        end

        def request_audio
          # delete expired cameras
          #@cams.delete_if { |cam| (cam[:activation_time] + @pig_configuration[:ddefault_service_time_camera]) < Time.now }
          
          @cams.each do |cam|
            logger.info "*** #{self.class.name}: Requesting audio from sensor #{cam[:name]} (#{cam[:url]}) ***"
            audio = IpCameraInterface.request_audio(cam[:url], cam[:duration])
            send_to_pipelines(audio, cam[:cam_id], cam[:source]) unless audio.nil?
          end
        end

        def send_to_pipelines(raw_data, cam_id, source)
          @service_manager.with_pipelines_interested_in(raw_data) do |pl|
            @pool.post do
              begin
                logger.info "*** #{self.class.name}: #{pl} is processing #{raw_data.length} bytes from #{source.to_s} ***"

                bench = pl.process(raw_data, cam_id.to_s, source)
                  unless @benchmark.nil? or bench.nil? or bench.empty?
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
