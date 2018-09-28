require 'concurrent'

require 'spf/common/logger'
require 'spf/common/exceptions'
require 'spf/common/extensions/fixnum'
require 'mqtt'

require_relative './configuration'
require_relative './json_handler'

module SPF
  module Controller
    class MqttInterface

      include SPF::Logging

      @@HOST = '127.0.0.1'
      #default port for MQTT
      @@PORT = 1883
      
      @@SEND_DATA_TIMEOUT = 5.seconds
      @@CONTROLLER_PORT = 52161

      def initialize(host, port)
	      @host = host
	      @port = port
      end

      def run
      	#SPF handles request on the 'request' topic
      	MQTT::Client.connect(@@HOST) do |req|
	      	req.get('request') do |_,request|
		        logger.debug "*** Received MQTT request: #{request}"
			      JsonHandler.translate_request(JSON.parse(request))
	 	      end
      	end
      end
    end
  end
end
