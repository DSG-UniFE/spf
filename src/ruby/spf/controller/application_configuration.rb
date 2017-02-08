require 'spf/common/logger'
require 'spf/common/validate'
require 'spf/common/exceptions'
require 'spf/common/extensions/fixnum'


module SPF
  module Controller
    class ApplicationConfiguration

    include SPF::Logging

      attr_reader :app_name, :opt

      private

        def initialize
          @app_name = nil
          @opt = Hash.new
        end

        def application(app_name, opt)
          @app_name = app_name
          @opt = opt
        end

      public

        def validate?
          SPF::Common::Validate.app_config?(@app_name, @opt)
        end

        def self.load_from_file(filename)
          # allow filename, string, and IO objects as input
          # raise ArgumentError, "File #{filename} does not exist!" unless File.exists?(File.join(@@APP_DIR, filename))
          raise ArgumentError, "*** #{self.class.name}: File '#{filename}' does not exist! ***" unless File.exists? filename

          # create configuration object
          conf = ApplicationConfiguration.new

          # Dir[File.join(APP_DIR, "*")].foreach do |conf_name|
          #   # take the file content and pass it to instance_eval
          #   conf.instance_eval(File.new(conf_name, 'r').read) if File.file?(conf_name)
          # end
          # take the file content and pass it to instance_eval
          # conf.instance_eval(File.new(File.join(@@APP_DIR, filename), 'r').read)
          conf.instance_eval(File.new(filename, 'r').read)

          raise SPF::Common::Exceptions::ConfigurationError, "*** #{self.class.name}: Configuration '#{filename}' not passed validate! ***" unless conf.validate?

          # return new object
          conf.opt
        end

    end

  end
end
