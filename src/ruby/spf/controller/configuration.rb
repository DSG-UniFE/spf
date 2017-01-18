require 'spf/common/validate'
require 'spf/common/logger'
require 'spf/common/exceptions'


module SPF
  module Controller
    class Configuration
      include SPF::Logging

      attr_reader :config

      private

        def initialize
          @config = Hash.new
        end

        def configuration(config)
          @config = config
          @config[:requests_port] = config[:requests_port].to_i
          @config[:manager_port] = config[:manager_port].to_i
        end

      public

        def validate?
          # check coordinates are valid, IPs are valid, ports are valid
          SPF::Common::Validate.ip? @config[:host] and
            SPF::Common::Validate.port? @config[:requests_port] and
            SPF::Common::Validate.port? @config[:manager_port]
        end

        def self.load_from_file(filename)
          # allow filename, string, and IO objects as input
          raise ArgumentError, "Controller: File #{filename} does not exist!" unless File.exists?(filename)

          # create configuration object
          conf = Configuration.new

          # take the file content and pass it to instance_eval
          conf.instance_eval(File.new(filename, 'r').read)

          # validate and finalize configuration
          raise SPF::Common::Exceptions::ConfigurationError, "Controller: Configuration not passed validate!" unless conf.validate?

          # return new object
          conf.config
        end

    end

  end
end
