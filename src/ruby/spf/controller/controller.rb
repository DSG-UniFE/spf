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

        @pig_sockets = Hash.new
        @pigs_tree = Geokdtree::Tree.new(2)
      end

      def run
        Thread.new { PigManager.new(@config[:host], @config[:manager_port], @pig_sockets, @pigs_tree).run }
        RequestsManager.new(@config[:host], @config[:requests_port], @pig_sockets, @pigs_tree).run
      end

    end
  end
end
