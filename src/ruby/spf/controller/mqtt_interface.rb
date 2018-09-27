require 'concurrent'

require 'spf/common/logger'
require 'spf/common/exceptions'
require 'spf/common/extensions/fixnum'

require_relative './configuration'

module SPF
  module Controller
    class MqttInterface

      include SPF::Logging

      @@HOST = '127.0.0.1'
      #default port for MQTT
      @@PORT = 1883

      #SPF handles request on the 'request' topic
      MQTT::Client.connect(@@HOST) do |req|
	      req.get('request') do |_,request|
		      logger.debug "*** Received MQTT request: #{request}"
		      translate_request(request)
	      end
      end

      # {
      # "Userid" : "Recon1",
      #   "RequestType": "surveillance/surveillance",
      #   "Service": "count objects",
      #   "CameraGPSLatitude" : "44.12121",
      #   "CameraGPSLongitude" : "12.21212",
      #   "CameraUrl": "http://weathercam.digitraffic.fi/C0150200.jpg"
      # }

      # REQUEST participants/find_text
      # User 3;44.838124,11.619786;find "water"
      #
      # OR
      #
      # REQUEST surveillance/surveillance
      # User 3;44.838124,11.619786;face_detection;https://example.info/camId.jpg

      #consider to pass the json instead of parsing and sending the message again
      def translate_request(data)
        if data.nil?
          return
        end
        logger.info "*** Received request: #{data} ***"
        Thread.new do
          socket = nil
          begin
            status = Timeout::timeout(@@SEND_DATA_TIMEOUT) do
              socket = TCPSocket.open("127.0.0.1", @@CONTROLLER_PORT)
              logger.debug ("REQUEST #{data['RequestType']} ")
              socket.puts("REQUEST #{data['RequestType']} ")
              socket.puts("User #{data['Userid']};#{data['CameraGPSLatitude']},#{data['CameraGPSLongitude']};#{data['Service']};#{data['CameraUrl']}")
              logger.debug("User #{data['Userid']};#{data['CameraGPSLatitude']},#{data['CameraGPSLongitude']};#{data['Service']};#{data['CameraUrl']}")
              logger.info "*** #{self.class.name}: Send request to controller for user #{data['Userid']} ***"
            end
          rescue Timeout::Error => e
            logger.warn "*** #{self.class.name}: Failed send request to controller for user #{data['Userid']}, timeout error ***"
          rescue => e
            logger.warn "*** #{self.class.name}: Exception #{e} ***"
            logger.warn "*** #{self.class.name}: Failed send request to controller for user #{data['Userid']}, controller is unreachable ***"
          ensure
            unless socket.nil?
              socket.close
            end
          end
        end

        logger.info "*** Finished translate_request for: #{data} ***"
      end
    end
  end
end
