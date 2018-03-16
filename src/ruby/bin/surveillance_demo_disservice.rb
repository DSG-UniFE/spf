#!/usr/bin/env ruby

SRC_RUBY_DIR = File.expand_path(File.join(File.dirname(__FILE__), '..'))
$LOAD_PATH.unshift(SRC_RUBY_DIR) unless $LOAD_PATH.include?(SRC_RUBY_DIR)
if RUBY_PLATFORM =~ /java/
  JARS_DIR = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'jars'))
  Dir["#{JARS_DIR}/*.jar"].each do |jar|
    $CLASSPATH << jar unless $CLASSPATH.include?(jar)
  end
end

require 'uri'
require 'json'
require 'java'
require 'socket'
require 'net/http'

require 'spf/common/validate'
require 'spf/common/extensions/fixnum'
require 'spf/common/extensions/thread_reporter'

java_import 'us.ihmc.aci.disServiceProxy.DisseminationServiceProxyListener'
java_import 'us.ihmc.aci.disServiceProxy.AsyncDisseminationServiceProxy'


class ResponseListener
  java_implements DisseminationServiceProxyListener

  attr_reader :n_receive_requests

  def initialize (ds_proxy, app_name, requests, n_requests)
    @ds_proxy = ds_proxy
    @app_name = app_name
    @requests = requests
    @n_requests = n_requests
    @n_receive_requests = 0
    @id_list = Array.new
  end

  java_signature 'dataArrived (String msgId, String sender, String groupName, int seqNum, String objectId,\
                               String instanceId, String mimeType, byte[] data, int metadataLength,\
                               short tag, byte priority, String queryId)'
  def dataArrived (msgId, sender, groupName, seqNum, objectId, instanceId,
                   mimeType, data, metadataLength, tag, priority, queryId)
    puts "\nReceived new IO with ID '#{msgId}' from '#{sender}'"
    puts "Application: #{groupName}"
    puts "ObjectID: #{objectId}"
    puts "IstanceID: #{instanceId}"

    if mimeType.eql? "text/plain"
      puts "Data: #{data}"
    else
      puts "Impossible to visualize data with MIME type #{mimeType}"
    end

    if @id_list.include? msgId
      puts "\nERROR: message with id '#{msgId}' already received!!!"
    else
      @id_list << msgId

      @n_receive_requests += instanceId.split(";")[1].to_i

      if @requests.has_key? groupName.to_sym
        @requests[groupName.to_sym][:end] << [Time.now.strftime("%H:%M:%S.%L"), instanceId]
      else
        puts "\nReceived message with a group name '#{groupName}' not present in @requests"
      end
    end

    if @n_receive_requests >= @n_requests
      unsubscribe()
    end
  end

  java_signature 'void chunkArrived (String msgId, String sender, String groupName, int seqNum, String objectId,\
                                     String instanceId, String mimeType, byte[] data, short nChunks, short totNChunks,\
                                     String chunkedMsgId, short tag, byte priority, String queryId)'
  def chunkArrived (msgId, sender, groupName, seqNum, objectId, instanceId, mimeType, data,
                    nChunks, totNChunks, chunkedMsgId, tag, priority, queryId)
    raise "chunkArrived: METHOD NOT IMPLEMENTED!"
  end

  java_signature 'void metadataArrived (String msgId, String sender, String groupName, int seqNum, String objectId,\
                                        String instanceId, String dataMimeType, byte[] metadata,\
                                        boolean dataChunked, short tag, byte priority, String queryId)'
  def metadataArrived (msgId, sender, groupName, seqNum, objectId, instanceId, dataMimeType,
                       metadata, dataChunked, tag, priority, queryId)
    raise "metadataArrived: METHOD NOT IMPLEMENTED!"
  end

  java_signature 'void dataAvailable (String msgId, String sender, String groupName, int seqNum, String objectId,\
                                      String instanceId, String mimeType, String id, byte[] metadata,\
                                      short tag, byte priority, String queryId)'
  def dataAvailable (msgId, sender, groupName, seqNum, objectId, instanceId,
                     mimeType, id, metadata, tag, priority, queryId)
    raise "dataAvailable: METHOD NOT IMPLEMENTED!"
  end

  def unsubscribe()
    # unsubscribe from the group and terminate current thread
    @ds_proxy.unsubscribe(@app_name)
    @ds_proxy.asynchThreadDone
  end

end

# CONTROLLER_URI the URI (http://controller_ip:port) of the SPF Controller
# http://localhost:8433
if ARGV.size != 1
  puts "ERROR!!! Correct usage is: jruby simple_client-dspro.rb <CONTROLLER_URI>"
  abort("Example: jruby simple_client-dspro.rb http://localhost:8433")
end

APPLICATION_CONFIG_DIR = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'etc', 'controller', 'app_configurations'))

applications = Dir.entries(APPLICATION_CONFIG_DIR)

# the REQUEST service is accessible at http://IP_CONTROLLER:8433/request
uri_request = URI(ARGV[0]) + "/request"
application_name = "surveillance"
n_requests = 1
cam_url = "http://weathercam.digitraffic.fi/C0150200.jpg"
camera_lat = "60.39023804760148"
camera_lon = "25.616391299785636"
requests = Hash.new

proxy = AsyncDisseminationServiceProxy.new(7843.to_java(:short), 60000.to_java(:long))
responseListener = ResponseListener.new(proxy, application_name, requests, n_requests)
begin
  proxy.init
  proxy.subscribe(application_name, 1.to_java(:byte), true.to_java(:boolean), true.to_java(:boolean), false.to_java(:boolean))
  proxy.registerDisseminationServiceProxyListener(responseListener)
  t = Java::JavaLang::Thread.new { proxy.run }
  t.start

  requests[application_name.to_sym] = Hash.new
  requests[application_name.to_sym][:start] = Array.new
  requests[application_name.to_sym][:end] = Array.new

  puts "Sending request to SPF::Controller (URI: #{uri_request})..."
  n_requests.times do |i|
    # The REQUEST call has the following format
    req = Net::HTTP::Post.new(uri_request, 'Content-Type' => 'application/json')

    req.body = {
      UserId: 'Recon1',
      RequestType: 'surveillance/surveillance',
      Service: "count objects",
      CameraGPSLatitude: camera_lat,
      CameraGPSLongitude: camera_lon,
      CameraUrl: cam_url
    }.to_json

    res = Net::HTTP.start(uri_request.hostname, uri_request.port) do |http|
      http.request(req)
    end

    requests[application_name.to_sym][:start] << [Time.now.strftime("%H:%M:%S.%L")]
    puts "\nSent request"

  end
  puts "Waiting for responses...\n"

  # wait up to 5 minutes for a response to arrive, and then exit
  t.join(5 * 60 * 1000)

  responseListener.unsubscribe()

  if responseListener.n_receive_requests == n_requests
    puts "\nReceived response"
  else
    puts "\nNo response received"
  end

  puts "Request: #{requests[application_name.to_sym][:start]}"
  puts "Response: #{requests[application_name.to_sym][:end]}"

  results = []
  requests[application_name.to_sym].each do |key, values|
    case key
    when :start
      values.each do |val|
        results << ["request", val].flatten
      end
    when :end
      values.each do |val|
        results << ["response", val].flatten
      end
    end
  end
  
  exit
rescue java.net.ConnectException => e
  Kernel.abort("ERROR: unable to connect to the DisServiceProxy instance - proxy down?")
rescue Errno::ECONNREFUSED => e
  Kernel.abort("ERROR: unable to open a TCP connection to #{HOST}:#{PORT} - SPF Controller down?")
rescue => e
  puts e.message
  puts e.backtrace
  Kernel.abort("ERROR: unknown error when trying to connect to the DisServiceProxy instance")
end
