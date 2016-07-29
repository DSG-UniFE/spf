# require 'spf/support/dsl_helper'

module SPF
  module Gateway

    class Configuration

      attr_reader :applications

      # TODO: how to make this private?
      def initialize(filename)
        @filename = filename
        #@applications = {}
        @services = {}
      end

      def application(name, options)
        #@applications[name.to_sym] = options
      end

      def validate
        # do nothing, at least for the moment
      end
      
      def register_svc(svc)
        @services[svc.svc_type] = svc unless @services.has_key?(svc.svc_type)
      end
      
      def is_service_available?(svc_type)
        @services.has_key?(svc_type)
      end
      
      def get_service_by_type(svc_type)
        @services[svc_type]
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
