#!/usr/bin/env ruby

SRC_RUBY_DIR = File.expand_path(File.join(File.dirname(__FILE__), '..'))
$LOAD_PATH.unshift(SRC_RUBY_DIR) unless $LOAD_PATH.include?(SRC_RUBY_DIR)
if RUBY_PLATFORM =~ /java/
  JARS_DIR = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'jars'))
  Dir["#{JARS_DIR}/*.jar"].each do |jar|
    $CLASSPATH << jar unless $CLASSPATH.include?(jar)
  end
end

require 'csv'
require 'java'
require 'socket'

require 'spf/common/validate'
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
    puts "Received so far #{@n_receive_requests} responses out of #{@n_requests}"

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
        puts "*** Requesting data ***"
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


if ARGV.size != 3
  abort("ERROR!!! Correct usage is: ruby dspro_simple_client.rb <IP_CONTROLLER> <APPLICATION_NAME> <#REQUESTS>")
end

unless SPF::Common::Validate.ip?(ARGV[0])
  abort("ERROR: Invalid ip!")
end

APPLICATION_CONFIG_DIR = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'etc', 'controller', 'app_configurations'))

applications = Dir.entries(APPLICATION_CONFIG_DIR)
unless applications.include? ARGV[1]
  abort("ERROR: Invalid application name!")
end

unless ARGV[2].to_i > 0
  abort("ERROR: Invalid number of requests!")
end

APPLICATION_NAME = ARGV[1]
HOST = ARGV[0]
PORT = 52161
N_REQUESTS = ARGV[2].to_i

requests = Hash.new

proxy = AsyncDSProProxy.new(7843.to_java(:short), 60000.to_java(:long))
responseListener = ResponseListener.new(proxy, APPLICATION_NAME, requests, N_REQUESTS)
begin
  rc = proxy.init
  if rc != 0
    raise "*** #{self.class.name}: DSProProxy init failed - proxy down? ***"
  end
  t = Java::JavaLang::Thread.new { proxy.run }
  t.start

  proxy.registerDSProProxyListener(responseListener)
  requests[APPLICATION_NAME.to_sym] = Hash.new
  requests[APPLICATION_NAME.to_sym][:start] = Array.new
  requests[APPLICATION_NAME.to_sym][:end] = Array.new

  N_REQUESTS.times do |i|
    socket = TCPSocket.new(HOST, PORT)

    case APPLICATION_NAME
    when "participants"
      socket.puts "REQUEST participants/find_text"
      socket.puts "User Giulio;40.010101,10.010101;find 'water'"
    when "surveillance"
      socket.puts "REQUEST surveillance/surveillance"
      socket.puts "User Giulio;40.010101,10.010101;count objects"
    else
      abort("ERROR: application not present in case/when!")
    end
    socket.close
    requests[APPLICATION_NAME.to_sym][:start] << [Time.now.strftime("%H:%M:%S.%L")]

    puts "\nSent #{i+1} request/s"

    if (i+1) != N_REQUESTS
      seconds_to_sleep = rand(1000...3000).to_f / 1000.0
      puts "\nSleep for #{seconds_to_sleep} seconds..."
      sleep(seconds_to_sleep)
    end

  end

  puts "\nWaiting for responses..."

  # wait up to 5 minutes for a response to arrive, and then exit
  t.join(5 * 60 * 1000)

  #terminate proxy
  proxy.requestTermination()

  if responseListener.n_receive_requests == N_REQUESTS
    puts "\nOh yeah, received #{responseListener.n_receive_requests} requests"
  else
    puts "\nOh no, received #{responseListener.n_receive_requests} of #{N_REQUESTS}"
  end

  puts "\nRequests: #{requests[APPLICATION_NAME.to_sym][:start]}"
  puts "\nResponse: #{requests[APPLICATION_NAME.to_sym][:end]}"

  results = []
  requests[APPLICATION_NAME.to_sym].each do |key, values|
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

  unless results.empty?
    benchmark_dir = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'benchmark'))
    unless Dir.exist? benchmark_dir
      Dir.mkdir benchmark_dir
    end
    benchmark_path = File.join(benchmark_dir, "client.results-#{Time.now}.csv")

    results.sort_by! { |el| el[1] }
    CSV.open(benchmark_path, "wb",
              :write_headers => true,
              :headers => ["REQ/RES", "Time", "Details"]) do |csv|
      results.each { |res| csv << res }
    end
    puts "\nSaved results into file"
  end

  puts "\nBye"
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
