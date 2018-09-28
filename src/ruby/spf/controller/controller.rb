require 'java'

require 'spf/common/logger'
require 'spf/common/extensions/thread_reporter'

require_relative './http_interface'
require_relative './pig_manager'
require_relative './configuration'
require_relative './requests_manager'
require_relative './mqtt_interface'

java_import 'utils.KdTree'


module SPF
  module Controller
    class Controller

    include SPF::Logging

      def initialize
        conf_filename_path = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'etc', 'controller', 'configuration'))
        begin
          @config = Configuration::load_from_file(conf_filename_path)
        rescue ArgumentError => e
          logger.error "*** #{self.class.name}: #{e.message} ***"
          exit
        rescue SPF::Common::Exceptions::ConfigurationError => e
          logger.error "*** #{self.class.name}: #{e.message} ***"
          exit
        end
        @pigs = Hash.new
        @pigs_tree = KdTree.new
      end

      def run
        Thread.new { PigManager.new(@pigs, @pigs_tree, @config[:host], @config[:manager_port]).run }
        Thread.new { RequestsManager.new(@pigs, @pigs_tree, @config[:host], @config[:requests_port]).run }
	Thread.new { MqttInterface.new('127.0.0.1', 1833).run }
        # Start Controller's HTTP Interface
        HttpInterface.run!
      end

    end
  end
end
