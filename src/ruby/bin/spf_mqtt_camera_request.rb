# SPF's MQTT Interface example
# make a request to the controller to acticate a surveillance service
# to a specified camera

require 'mqtt'
require 'json'

#simple mockup to test the mqtt controller
if ARGV.size < 1
	abort ("Error! Usage spf_camera_request <Controller_Uri> [<CAM_Url> <latitude> <longitude>]")
end


case ARGV.size
	when 1
		cam_url = "http://weathercam.digitraffic.fi/C0150200.jpg"
		camera_lat = "44.12121"
		camera_lon = "44.12121"
	when 2
		cam_url = ARGV[1]
		camera_lat = "44.12121"
		camera_lon = "44.12121"
	when 3, 4
		cam_url = ARGV[1]
		camera_lat = ARGV[2]
		camera_lon = ARGV[3]
end

#make a request using the 'request' topic

puts "Sending request to SPF::Controller at #{ARGV[0]}"

MQTT::Client.connect(ARGV[0]) do |c|

	request_message = {UserId: 'Recon1', RequestType: 'surveillance/surveillance', Service: "count objects", CameraGPSLatitude: camera_lat, CameraGPSLongitude: camera_lon, CameraUrl: cam_url}.to_json
	c.publish('request', request_message)
end

puts "Request sent to the SPF controller"
