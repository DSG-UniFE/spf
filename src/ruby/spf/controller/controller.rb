require 'geokdtree'

require 'spf/common/extensions/thread_reporter'

require_relative './requests_manager'
require_relative './pig_manager'
require_relative './configuration'


module SPF
  module Controller
    class Controller

      def initialize
        conf_filename = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'etc', 'controller', 'configuration'))
        @config = Configuration::load_from_file(conf_filename)

        @pigs = Hash.new
        @pigs_tree = Geokdtree::Tree.new(2)
      end

      def run
        Thread.new { PigManager.new(@pigs, @pigs_tree, @config[:host], @config[:manager_port]).run }
        RequestsManager.new(@pigs, @pigs_tree, @config[:host], @config[:requests_port]).run
      end

    end
  end
end
