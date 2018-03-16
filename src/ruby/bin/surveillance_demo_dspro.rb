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

require 'spf/common/extensions/fixnum'
require 'spf/common/extensions/thread_reporter'

java_import 'us.ihmc.aci.dspro2.DSProProxyListener'
java_import 'us.ihmc.aci.dspro2.AsyncDSProProxy'


class ResponseListener
  java_implements DSProProxyListener

  attr_reader :n_receive_requests

  def initialize (ds_proxy, app_name, requests, n_requests)
    @ds_proxy = ds_proxy
    @app_name = app_name
    @requests = requests
    @n_requests = n_requests
    @n_receive_requests = 0
    @id_list = Array.new
  end

  java_signature 'dataArrived (String dsproId, String groupName, String objectId,\
                                String instanceId, String annotatedObjMsgId,\
                                String mimeType, byte[] data, short chunkNumber,\
                                short totChunksNumber, String callbackParameters)'
  def dataArrived (dsproId, groupName, objectId, instanceId,
                   annotatedObjMsgId, mimeType, data, chunkNumber, totChunksNumber, callbackParameters)
    puts "\nReceived new IO with ID '#{dsproId}'"
    puts "Application: #{groupName}"
    puts "ObjectID: #{objectId}"
    puts "ChunkNumber: #{chunkNumber}"
    puts "TotChunksNumber: #{totChunksNumber}"

    if mimeType.eql? "text/plain"
      puts "Data: #{data}"
    else
      puts "Impossible to visualize data with MIME type #{mimeType}"
    end

    if @id_list.include? dsproId
      puts "\nERROR: message with id '#{dsproId}' already received!!!"
    else
      @id_list << dsproId

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

  java_signature 'void metadataArrived (String dsproId, String groupName, String referredDataObjectId,\
                                        String referredDataInstanceId, String xMLMetadata,\
                                        String referredDataId, String queryId)'
  def metadataArrived (dsproId, groupName, referredDataObjectId,
                        referredDataInstanceId, xMLMetadata, referredDataId, queryId)
        puts "\nReceived new metadata with ID '#{dsproId}'"
        puts "Application: #{groupName}"
        puts "ObjectID: #{referredDataObjectId}"
        puts "ReferredDataId #{referredDataId}"
        puts "XMLMetadata: \n #{xMLMetadata}"
        puts "\n*** Requesting data ***"
        data_wrapper = @ds_proxy.getData(referredDataId)
        unless data_wrapper.nil?
          data = data_wrapper._data
          # get the mimeType from the XML
          mimeType = "text/plain"
          puts "Data from getData #{data} #{mimeType}"
          if mimeType.eql? "text/plain"
            puts "Data: #{data}"
          else
            puts "Impossible to visualize data with MIME type #{mimeType}"
          end

          if @id_list.include? dsproId
            puts "\nERROR: message with id '#{dsproId}' already received!!!"
          else
            @id_list << dsproId

            @n_receive_requests += referredDataInstanceId.split(";")[1].to_i

            if @requests.has_key? groupName.to_sym
              @requests[groupName.to_sym][:end] << [Time.now.strftime("%H:%M:%S.%L"), referredDataInstanceId]
            else
              puts "\nReceived message with a group name '#{groupName}' not present in @requests"
            end
          end
          puts "Received so far #{@n_receive_requests} responses out of #{@n_requests}"
          if @n_receive_requests >= @n_requests
            unsubscribe()
          end
        end
  end

  java_signature 'boolean pathRegistered (NodePath path, String nodeId, String teamId, String mission)'
  def pathRegistered (path, nodeId, teamId, mission)
    raise "pathRegistred: METHOD NOT IMPLEMENTED"
  end

  java_signature 'boolean positionUpdated (float latitude, float longitude, float altitude, String nodeId)'
  def positionUpdated (latitude, longitude, altitude, nodeId)
    raise "positionUpdated: METHOD NOT IMPLEMENTED!"
  end

  java_signature 'void newNeighbor (String peerID)'
  def newNeighbor (peerID)
    raise "newNeighbor: METHOD NOT IMPLEMENTED!"
  end

  java_signature 'void deadNeighbor (String peerID)'
  def deadNeighbor (peerID)
    raise "deadNeighbor: METHOD NOT IMPLEMENTED!"
  end

  def unsubscribe()
    # Terminate current thread
    @ds_proxy.requestTermination
  end

end

# CONTROLLER_URI the URI (http://controller_ip:port) of the SPF Controller
# http://localhost:8433
if ARGV.size != 1
  puts "ERROR!!! Correct usage is: jruby simple_client-dspro.rb <CONTROLLER_URI>"
  abort("Example: jruby simple_client-dspro.rb http://localhost:8433")
end

APPLICATION_CONFIG_DIR = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'etc', 'controller', 'app_configurations'))

# the REQUEST service is accessible at http://IP_CONTROLLER:8433/request
uri_request = URI(ARGV[0]) + "/request"
application_name = "surveillance"
n_requests = 1
cam_url = "http://weathercam.digitraffic.fi/C0150200.jpg"
camera_lat = "60.39023804760148"
camera_lon = "25.616391299785636"
requests = Hash.new

proxy = AsyncDSProProxy.new(7843.to_java(:short), 60000.to_java(:long))
responseListener = ResponseListener.new(proxy, application_name, requests, n_requests)
begin
  rc = proxy.init
  if rc != 0
    raise "*** #{self.class.name}: DSProProxy init failed - proxy down? ***"
  end
  t = Java::JavaLang::Thread.new { proxy.run }
  t.start

  proxy.registerDSProProxyListener(responseListener)
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

  # terminate proxy
  proxy.requestTermination()

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
  Kernel.abort("ERROR: unable to connect to the DSProProxy instance - proxy down?")
rescue Errno::ECONNREFUSED => e
  Kernel.abort("ERROR: unable to open a TCP connection to #{HOST}:#{PORT} - SPF Controller down?")
rescue => e
  puts e.message
  puts e.backtrace
  Kernel.abort("ERROR: unknown error when trying to connect to the DSProProxy instance")
end
