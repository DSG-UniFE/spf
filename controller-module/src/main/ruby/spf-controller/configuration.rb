require_relative './service_manager'
require_relative './application'
require 'pig_details'
require 'spf-common/validate'
require 'spf-common/logger'

module SPF
  module Controller

    class Configuration
      include SPF::Logging

      attr_reader :pigs

      private

        def initialize
          @pigs = []
        end

        def validate
          # check coordinates are valid, IPs are valid, ports are valid
          @pigs.delete_if {|pig| SPF::Validate.pig? pig }
        end

      def add_pigs(pigs)
        @pigs = pigs
      end

      public

        def self.load_from_file(filename)
          # allow filename, string, and IO objects as input
          raise ArgumentError, "File #{filename} does not exist!" unless File.exists?(filename)

          # create configuration object
          conf = Configuration.new

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
