# require 'spf/support/dsl_helper'

module SPF
  module Gateway

    class Configuration

      attr_reader :applications
      attr_reader :application_configurations # consider making private

      # TODO: how to make this private?
      def initialize(filename)
        @filename = filename
        @service_manager = ServiceManager.new
      end

      def application(name, options)
        @application_configurations[name.to_sym] = options
      end

      def validate
        @applications = @application_configurations.map do |conf|
          Application.new(conf, @service_manager)
        end
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
