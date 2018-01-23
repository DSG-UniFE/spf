require 'socket'
#Emulate a "SPF Camera" by sending an image to the Gateway DataListener

if ARGV.size < 2
  abort("ERROR!!! Correct usage is: ruby fake_camera.rb <PIG_IP> <IMAGE_FILENAME> [<LAT> <LON>]")
end

pig_address = ARGV[0]

image_file = ARGV[1]

if ARGV.size == 4 then
	lat = ARGV[2]
	lon = ARGV[3]
else
	lat = "44.010101"
	lon = "11.010101"
end

begin
	#open image file
	image = open image_file
rescue => exception
	Kernel.abort("ERROR: Perhaps #{image_file} does not exist?")
end


#connect to the PIG

#default address and port are localhost and 2160
#open a connection to the gateway
s = TCPSocket.new pig_address, 2160

#IMAGE CAM_ID LAT LON IMAGE_SIZE
header = "IMAGE  666 " + lat + " " + lon + " " + image.size.to_s
s.puts header
 
puts "Sent raw_data to the PIG, header #{header}"
 
#Send the picture to the PIG
s.puts image.read

response = s.gets
s.close

puts "Response from PIG: #{response}"

image.close


