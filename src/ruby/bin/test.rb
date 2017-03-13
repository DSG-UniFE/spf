#!/usr/bin/env ruby

if RUBY_PLATFORM =~ /java/
  opencv_jar = '/usr/share/java/opencv.jar'
  $CLASSPATH << opencv_jar unless $CLASSPATH.include?(opencv_jar)
  JARS_DIR = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'jars'))
  Dir["#{JARS_DIR}/*.jar"].each do |jar|
    $CLASSPATH << jar unless $CLASSPATH.include?(jar)
  end
end

$TESSDATA_PREFIX = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'resources'))

SRC_RUBY_DIR = File.expand_path(File.join(File.dirname(__FILE__), '..'))
$LOAD_PATH.unshift(SRC_RUBY_DIR) unless $LOAD_PATH.include?(SRC_RUBY_DIR)


require 'java'
require 'concurrent'

require 'spf/common/logger'
require 'spf/gateway/configuration'
require 'spf/gateway/service_manager'
require 'spf/gateway/disservice_handler'
require 'spf/gateway/configuration_agent'

java_import 'it.unife.spf.FaceRecognition'

include SPF::Logging

puts "\n"
puts "++++++++++++++++++++++++++++++++++++"
puts "+++++                          +++++"
puts "+++++                          +++++"
puts "+++++          TEST            +++++"
puts "+++++                          +++++"
puts "+++++                          +++++"
puts "++++++++++++++++++++++++++++++++++++"
puts "\n"


if ARGV.size != 3
  abort("ERROR!!! Correct usage is: bundle exec jruby test.rb <SINGLE_FACE/SINGLE_SERVICE/MULTIPLE_FACE/MULTIPLE_SERVICE> <#REQUESTS> <SLEEP_TIME>")
end

unless ["single_face", "single_service", "multiple_face", "multiple_service"].include? ARGV[0].downcase
  abort("ERROR: Invalid argument (single/multiple)!")
end

unless ARGV[1].to_i > 0
  abort("ERROR: Invalid number of requests!")
end

unless ARGV[2].to_i >= 0
  abort("ERROR: Invalid number of sleep time!")
end


EXECUTION_TYPE = ARGV[0].to_sym
N_REQUESTS = ARGV[1].to_i
SLEEP_TIME = ARGV[2].to_i

accepted_formats = [".png"]

# Retrieve instances of Service Manager and DisService Handler
service_manager = SPF::Gateway::ServiceManager.new
disservice_handler = SPF::Gateway::DisServiceHandler.new

config_path = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'etc', 'gateway', 'pig_configuration'))
# Read Pig Configuration
pig_config = SPF::Gateway::PIGConfiguration.load_from_file(config_path, service_manager, disservice_handler)

service_manager.set_tau_test pig_config.tau_test

app_path = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'etc', 'controller', 'app_configurations', 'surveillance'))
app_config = File.read(app_path)

pig_config.reprogram(app_config)

# find service
svc = service_manager.get_service_by_name("surveillance".to_sym, "basic".to_sym)
logger.error "No service activated" if svc.nil?

# bring service up again if down
service_manager.restart_service(svc) unless svc.active?

svc.register_request("User Pippo;40.010101,10.010101;count people ")

if EXECUTION_TYPE == :multiple_service or EXECUTION_TYPE == :multiple_face
  queue_size = pig_config.queue_size
  queue = Array.new
  raw_data_index = Concurrent::AtomicFixnum.new
  semaphore = Mutex.new
  pool = Concurrent::ThreadPoolExecutor.new(
    min_threads: pig_config.min_thread_size,
    max_threads: pig_config.max_thread_size,
    max_queue: pig_config.max_queue_thread_size
  )
end

counter = 0
xml_path = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'resources', 'images'))

image_dir_path = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'resources', 'images'))
unless File.directory? image_dir_path
  abort("ERROR: nonexistent folder!")
end
images_path = Dir.glob(File.expand_path(File.join(image_dir_path, '*.png')))
unless images_path.size > N_REQUESTS
  abort("ERROR: in the directory there are not enough images!")
end
images_path.sort.each do |image|
  next if File.directory? image
  accepted_formats.include? File.extname(image)

  raw_data = File.read(image)
  case EXECUTION_TYPE

  when :single_face
    FaceRecognition.doFaceRec(raw_data.to_java_bytes, xml_path)

  when :single_service
    cam_id = "123"
    gps = Hash.new
    gps[:lat] = "41.010101"
    gps[:lon] = "11.010101"
    service_manager.with_pipelines_interested_in(raw_data) do |pl|
      pl.process(raw_data, cam_id, gps)
    end

  when :multiple_face
    loop do
      if pool.remaining_capacity == 0
        sleep(0.1)
        next
      end
      begin
        pool.post do
          begin
            semaphore.synchronize { FaceRecognition.doFaceRec(raw_data.to_java_bytes, xml_path) }
          rescue => e
            logger.error "*** #{self.class.name}: unexpected error, #{e.message} ***"
            logger.error e.backtrace
          ensure
            raw_data = nil
          end
        end
      rescue Concurrent::RejectedExecutionError
        logger.fatal "*** #{self.class.name}: fallback policy error, this error should not happen ***"
      ensure
        break
      end
    end

  when :multiple_service
    cam_id = "123"
    gps = Hash.new
    gps[:lat] = "41.010101"
    gps[:lon] = "11.010101"

    service_manager.with_pipelines_interested_in(raw_data) do |pl|
      loop do
        if pool.remaining_capacity == 0
          sleep(0.1)
          next
        end
        begin
          pool.post do
            begin
              pl.process(raw_data, cam_id, gps)
            rescue => e
              logger.error "*** #{self.class.name}: unexpected error, #{e.message} ***"
              logger.error e.backtrace
            ensure
              raw_data = nil
            end
          end
        rescue Concurrent::RejectedExecutionError
          logger.fatal "*** #{self.class.name}: fallback policy error, this error should not happen ***"
        ensure
          break
        end
      end
    end
  end
  counter += 1

  if counter > 1
    logger.info "*** Processed #{counter} images ***"
  else
    logger.info "*** Processed #{counter} image ***"
  end

  if counter >= N_REQUESTS
    if EXECUTION_TYPE == :multiple_service or EXECUTION_TYPE == :multiple_face
      logger.info "*** Waiting ThreadPoolExecutor... ***"
      loop do
        if pool.completed_task_count == N_REQUESTS
          break
        else
          sleep(1)
        end
      end
    end
    break
  end

  sleep(SLEEP_TIME)
end
