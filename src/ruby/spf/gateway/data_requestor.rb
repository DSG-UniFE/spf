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

      def initialize(cameras, data_queue)
        @cams = cameras
        @data_queue = data_queue
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
            logger.info "*** #{self.class.name}: Requesting photo from sensor #{cam[:name]} (#{cam[:url]}) #{cam[:source]} ***"
            image = IpCameraInterface.request_photo(cam[:url])
	          if image.nil?
		          logger.warn "Retrieved nil image from sensor: #{cam[:name]}"
	          end
            send_to_data_queue(image, cam[:cam_id], cam[:source]) unless image.nil?
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

        def send_to_data_queue(raw_data, cam_id, source)
          @data_queue.push(raw_data, cam_id, source)
          logger.debug "*** #{self.class.name}: Pushed data from sensor #{cam_id} #{source} in queue ***"
        end

    end
  end
end
