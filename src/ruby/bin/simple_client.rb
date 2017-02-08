#!/usr/bin/env ruby

SRC_RUBY_DIR = File.expand_path(File.join(File.dirname(__FILE__), '..'))
$LOAD_PATH.unshift(SRC_RUBY_DIR) unless $LOAD_PATH.include?(SRC_RUBY_DIR)
if RUBY_PLATFORM =~ /java/
  JARS_DIR = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'jars'))
  Dir["#{JARS_DIR}/*.jar"].each do |jar|
    $CLASSPATH << jar unless $CLASSPATH.include?(jar)
  end
end

#require 'kernel'
require 'socket'
require 'java'

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
  end

  java_signature 'dataArrived (String msgId, String sender, String groupName, int seqNum, String objectId,\
                               String instanceId, String mimeType, byte[] data, int metadataLength,\
                               short tag, byte priority, String queryId)'
  def dataArrived (msgId, sender, groupName, seqNum, objectId, instanceId,
                   mimeType, data, metadataLength, tag, priority, queryId)
    puts "Received new IO with ID #{msgId} from #{sender}"
    puts "Application: #{groupName}"
    puts "ObjectID: #{objectId}"
    puts "IstanceID: #{instanceId}"

    @n_receive_requests += instanceId.split(";")[1].to_i

    if mimeType.eql? "text/plain"
      puts "Data: #{data}"
    else
      puts "Impossible to visualize data with MIME type #{mimeType}"
    end

    if @requests.has_key? groupName.to_sym
      @requests[groupName.to_sym][:end] << [Time.now.strftime("%H:%M:%S.%L"), instanceId]
    else
      puts "Received message with a group name '#{groupName}' not present in @requests"
    end
    
    if @n_receive_requests == @n_requests
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


if ARGV.size != 3
  abort("ERROR!!! Correct usage is: ruby simple_client.rb <IP_CONTROLLER> <APPLICATION_NAME> <#REQUESTS>")
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

proxy = AsyncDisseminationServiceProxy.new(7843.to_java(:short), 60000.to_java(:long))
responseListener = ResponseListener.new(proxy, APPLICATION_NAME, requests, N_REQUESTS)
begin
  proxy.init
  proxy.subscribe(APPLICATION_NAME, 1.to_java(:byte), true.to_java(:boolean), true.to_java(:boolean), false.to_java(:boolean))
  proxy.registerDisseminationServiceProxyListener(responseListener)
  t = Java::JavaLang::Thread.new { proxy.run }
  t.start

  requests[APPLICATION_NAME.to_sym] = Hash.new
  requests[APPLICATION_NAME.to_sym][:start] = Array.new
  requests[APPLICATION_NAME.to_sym][:end] = Array.new

  N_REQUESTS.times do |i|
    socket = TCPSocket.new(HOST, PORT)

    case APPLICATION_NAME
    when "participants"
      socket.puts "REQUEST participants/find_text"
      socket.puts "User Giulio;{:lat=>44.010101,:lon=>11.010101};find 'water'"
    when "surveillance"
      socket.puts "REQUEST surveillance/basic"
      socket.puts "User Giulio;{:lat=>44.010101,:lon=>11.010101};count objects"
    else
      abort("ERROR: application not present in case/when!")
    end
    socket.close
    requests[APPLICATION_NAME.to_sym][:start] << [Time.now.strftime("%H:%M:%S.%L")]

    puts "\nSent #{i+1} request/s"

    if (i+1) != N_REQUESTS
      seconds_to_sleep = rand(1000...3000).to_f / 1000.0
      puts "Sleep for #{seconds_to_sleep} seconds..."
      sleep(seconds_to_sleep)
    end

  end

  puts "\nWaiting for responses..."

  # wait up to 5 minutes for a response to arrive, and then exit
  t.join(5 * 60 * 1000)

  responseListener.unsubscribe()

  if responseListener.n_receive_requests == N_REQUESTS
    puts "\nOh yeah, received #{N_REQUESTS} requests"
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

  results.sort_by! { |el| el[1] }
  File.open("results-#{Time.now}.csv", "w") do |f|
    f.puts "REQ/RES,Time,Details"
    results.each do |res|
      f.puts "#{res[0]},#{res[1]},#{res[2]}"
    end
    puts "\nSaved results into file"
  end

  puts "\nBye"
  exit
rescue java.net.ConnectException => e
  Kernel.abort("ERROR: unable to connect to the DisServiceProxy instance - proxy down?")
rescue Errno::ECONNREFUSED => e
  Kernel.abort("ERROR: unable to open a TCP connection to #{HOST}:#{PORT} - SPF Controller down?")
rescue => e
  puts e.backtrace
  Kernel.abort("ERROR: unknown error when trying to connect to the DisServiceProxy instance")
end
