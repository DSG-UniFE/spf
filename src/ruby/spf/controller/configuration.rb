require 'spf/common/validate'
require 'spf/common/logger'

module SPF
  module Controller

    class Configuration
      include SPF::Logging

      attr_reader :pigs

      private

        def initialize
          @pigs = []
        end

      public

        def validate
          # check coordinates are valid, IPs are valid, ports are valid
          @pigs.delete_if {|pig| !SPF::Common::Validate.pig? pig }
        end

        def self.load_from_file(filename)
          # allow filename, string, and IO objects as input
          raise ArgumentError, "Controller: File #{filename} does not exist!" unless File.exists?(filename)

          # create configuration object
          conf = Configuration.new

          # take the file content and pass it to instance_eval
          conf.instance_eval(File.new(filename, 'r').read)

          # validate and finalize configuration
          conf.validate

          # return new object
          conf.pigs
        end

    end

  end
end
