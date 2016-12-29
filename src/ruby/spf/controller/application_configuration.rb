require 'spf/common/logger'
require 'spf/common/validate'
require 'spf/common/extensions/fixnum'

module SPF
  module Controller

    class ApplicationConfiguration
      include SPF::Logging

      # Setup absolute path for app directory
      # @@APP_DIR = File.join('etc', 'controller', 'app_configurations')

      attr_reader :conf

      private

        def initialize
          @conf = {}
        end

        def validate(opt)
          SPF::Common::Validate.conf?(opt)
        end

        def application(name, opt)
          if validate(opt)
            @conf[name.to_sym] ||= opt
          else
            logger.warn("Controller: Configuration \"#{name}\" is not valid")
          end
        end

      public

        def self.load_from_file(filename)
          # allow filename, string, and IO objects as input
          # raise ArgumentError, "File #{filename} does not exist!" unless File.exists?(File.join(@@APP_DIR, filename))
          raise ArgumentError, "Controller: File #{filename} does not exist!" unless File.exists? filename

          # create configuration object
          conf = ApplicationConfiguration.new

          # Dir[File.join(APP_DIR, "*")].foreach do |conf_name|
          #   # take the file content and pass it to instance_eval
          #   conf.instance_eval(File.new(conf_name, 'r').read) if File.file?(conf_name)
          # end
          # take the file content and pass it to instance_eval
          # conf.instance_eval(File.new(File.join(@@APP_DIR, filename), 'r').read)
          conf.instance_eval(File.new(filename, 'r').read)

          # return new object
          conf.conf
        end

    end

  end
end
