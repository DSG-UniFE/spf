require 'java'

require 'spf/common/logger'
require 'spf/common/extensions/thread_reporter'

require_relative './https_interface'
require_relative './pig_manager'
require_relative './configuration'
require_relative './requests_manager'

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

        # Start Sinatra web interface
        HttpsInterface.run!
        # Rack::Handler::WEBrick.run HttpsInterface, webrick_options
      end

    end
  end
end
