# SPF's HTTP Interface example
# make a request to the controller to acticate a surveillance service
# to a specified camera

require 'net/http'
require 'uri'
require 'json'

# Controller_URI the URI (http://controller_ip:port) of the SPF Controller
# http://localhost:8433
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


# the REQUEST service is accessible at http://IPController:8433/request 

uriRequest = URI(ARGV[0]) + "/request"
puts "Uri #{uriRequest}"

# The REQUEST call has the following format
req = Net::HTTP::Post.new(uriRequest, 'Content-Type' => 'application/json')

json_request = {UserId: 'Recon1', RequestType: 'surveillance/basic', Service: "count objects", CameraGPSLatitude: camera_lat, CameraGPSLongitude: camera_lon,CameraUrl: cam_url}.to_json

puts "Sending #{json_request} to SPF::Controller"

req.body = {UserId: 'Recon1', RequestType: 'surveillance/basic', Service: "count objects", CameraGPSLatitude: camera_lat, CameraGPSLongitude: camera_lon,
			 CameraUrl: cam_url}.to_json

res = Net::HTTP.start(uriRequest.hostname, uriRequest.port) do |http|
  http.request(req)
end

