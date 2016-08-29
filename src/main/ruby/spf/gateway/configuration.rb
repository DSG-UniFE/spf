require_relative './service_manager'
require_relative './application'

module SPF
  module Gateway

    class PIGConfiguration

      attr_reader :applications

      ############################################################
      # TODO: make the following methods private
      ############################################################
      def initialize(filename)
        @filename = filename
        @service_manager = ServiceManager.new
        @applications = {}
      end

      def application(name, options)
        @applications[name.to_sym] = Application.new(name, options, @service_manager)
      end
      ############################################################
      # TODO: make the methods above private
      ############################################################

      def validate
      end

      def self.load_from_file(filename)
        # allow filename, string, and IO objects as input
        raise ArgumentError, "File #{filename} does not exist!" unless File.exists?(filename)

        # create configuration object
        conf = Configuration.new(filename)

        # take the file content and pass it to instance_eval
        conf.instance_eval(File.new(filename, 'r').read)

        # validate and finalize configuration
        conf.validate

        # return new object
        conf
      end

    end

  end
end
