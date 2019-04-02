require 'java'
require 'concurrent'

require 'spf/common/logger'
require 'spf/gateway/configuration'
require 'spf/gateway/data_listener'
require 'spf/gateway/data_requestor'
require 'spf/gateway/service_manager'
require 'spf/gateway/data_processor'
require 'spf/gateway/dissemination_handler'
require 'spf/gateway/configuration_agent'


module SPF
  module Gateway
    class PIG

    include SPF::Logging

      @@LOCATION = {}

      def initialize(benchmark=nil)
        begin
          camera_path = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'etc', 'gateway', 'ip_cameras'))
          config_path = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'etc', 'gateway', 'pig_configuration'))
          dissemination_path = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'etc', 'gateway', 'dissemination_configuration'))
          dissemination_start_path = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'resources', 'scripts', 'dissemination_start.sh'))

          # Retrieve instances of Service Manager and Dissemination Handler
          #load Dissemination config from file
          dissemination_config = SPF::Gateway::DisseminationConfiguration.load_from_file(dissemination_path)

          # Start Dissemination handler
          # Running also the disseminator
          if dissemination_config.disseminator_address.eql? "127.0.0.1" or dissemination_config.disseminator_address.eql? "localhost"
            logger.info "*** #{self.class.name}: Starting #{dissemination_config.dissemination_type} locally... ***"
            if dissemination_config.dissemination_type.downcase.eql? 'DSPro'.downcase
              unless `pgrep DisService`.empty?
                `pkill -f DisService`
              end
              if `pgrep DSPro`.empty? and not dissemination_config.dspro_path.empty? and File.exist? dissemination_config.dspro_path
                if not dissemination_config.dspro_config_path.empty? and File.exist? dissemination_config.dspro_config_path
                  builder = java.lang.ProcessBuilder.new("sh", "#{dissemination_start_path}", "#{dissemination_config.dspro_path}", "#{dissemination_config.dspro_config_path}")
                  proc = builder.start()
                  logger.info "*** #{self.class.name}: #{dissemination_config.dissemination_type} started with configuration file ***"
                  # pid = spawn("cd /home/pi/dspro; #{dissemination_config.dspro_path} -c #{dissemination_config.dspro_config_path}", [:out, :err]=>"/dev/null")
                  # Process.detach(pid)
                  # logger.info "*** #{self.class.name}: #{dissemination_config.dissemination_type} started with configuration file, PID: #{pid} ***"
                end
              end

            elsif dissemination_config.dissemination_type.downcase.eql? 'DisService'.downcase
              unless `pgrep DSPro`.empty?
                `pkill -f DSPro`
              end
              if `pgrep DisService`.empty? and not dissemination_config.disservice_path.empty? and File.exist? dissemination_config.disservice_path
                if dissemination_config.disservice_config_path.empty? or not File.exist? dissemination_config.disservice_config_path
                  builder = java.lang.ProcessBuilder.new("sh", "#{dissemination_start_path}", "#{dissemination_config.disservice_path}")
                  proc = builder.start()
                  logger.info "*** #{self.class.name}: #{dissemination_config.dissemination_type} started ***"
                  # pid = spawn("#{dissemination_config.disservice_path}", [:out, :err]=>"/dev/null")
                  # Process.detach(pid)
                  # logger.info "*** #{self.class.name}: #{dissemination_config.dissemination_type} started, PID: #{pid} ***"
                else
                  builder = java.lang.ProcessBuilder.new("sh", "#{dissemination_start_path}", "#{dissemination_config.disservice_path}", "#{dissemination_config.disservice_config_path}")
                  proc = builder.start()
                  logger.info "*** #{self.class.name}: #{dissemination_config.dissemination_type} started with configuration file ***"
                  # pid = spawn("#{dissemination_config.disservice_path} -c #{dissemination_config.disservice_config_path}", [:out, :err]=>"/dev/null")
                  # Process.detach(pid)
                  # logger.info "*** #{self.class.name}: #{dissemination_config.dissemination_type} started with configuration file, PID: #{pid} ***"
                end
                sleep(5)
              end
            else
              logger.error "*** #{self.class.name}: Error dissemination_type not configured ***"
              exit
            end
          else
            logger.info "*** #{self.class.name}: Try connecting to MQTT broker ***"
            #logger.info "*** #{self.class.name}: Try connecting to #{dissemination_config.dissemination_type} at the address #{disseminator_address}:#{disseminator_port}... ***"
          end

          @service_manager = SPF::Gateway::ServiceManager.new
          @dissemination_handler = SPF::Gateway::DisseminationHandler.new(SPF::Gateway::DisseminationHandler.DEFAULT_APP_ID,
            SPF::Gateway::DisseminationHandler.DEFAULT_POLLING_TIME, dissemination_config.dissemination_type,
            dissemination_config.disseminator_address, dissemination_config.disseminator_port)

          # Read Pig Configuration (now only the location - gps coordinates)
          @config = SPF::Gateway::PIGConfiguration.load_from_file(config_path, @service_manager, @dissemination_handler)
          # init empty cameras_config Array
          @cameras_config = []
          #@cameras_config = SPF::Gateway::PIGConfiguration.load_cameras_from_file(camera_path, @service_manager, @dissemination_handler)

          # topic for MQTT
          @mqtt_topics = ["sensors"] 

          @service_manager.set_tau_test @config.tau_test

          @data_queue = SPF::Gateway::DataProcessor.new(@service_manager,
                                                          benchmark,
                                                          @config.min_thread_size,
                                                          @config.max_thread_size,
                                                          @config.max_queue_thread_size,
                                                          @config.queue_size)
        rescue ArgumentError => e
          logger.error "*** #{self.class.name}: #{e.message} ***"
          exit
        rescue SPF::Common::Exceptions::ConfigurationError => e
          logger.error "#{e.message}"
          exit
        end
        @@LOCATION[:lat] = @config.location[:lat]
        @@LOCATION[:lon] = @config.location[:lon]
      end

      def self.location
        @@LOCATION
      end

      def run
        Thread.new { @data_queue.run }
        Thread.new { SPF::Gateway::DataListener.new(@data_queue).run }
        Thread.new { SPF::Gateway::DataRequestor.new(@cameras_config, @data_queue).run }
        Thread.new { SPF::Gateway::MQTTDataListener.new(@mqtt_topics).run }
        SPF::Gateway::ConfigurationAgent.new(@service_manager, @config,
                                              @config.controller_address,
                                              @config.controller_port, {}, @cameras_config).run
      end

    end
  end
end
