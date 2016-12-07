require_relative './application'
require_relative ''

module SPF
  module Gateway

    class Configuration

      attr_reader :applications
    
      CONFIG_FOLDER = "./"

      ############################################################
      # TODO: make the following methods private
      ############################################################
      
      def initialize(filename)
        @filename = filename
        @service_manager = ServiceManager.instance
        @applications = {}
        # NOTE: added disservice instance needed by Application.new
        @disservice_handler = DisServiceHandler.new
      end

      def application(name, options)
        @applications[name.to_sym] = Application.new(name, options, @service_manager, @disservice_handler)
      end

      def location(loc)
        @location = loc
      end

      def modify_application(name, options)
        options.each_key do |k|
          case k in

            # TODO: implement the change of configuration params
            :new_service_policy
            ...
          @applications[name.to_sym].send(k)

        end
      end

      ############################################################
      # TODO: make the methods above private
      ############################################################

      #NOTE : Verify application validation
      def validate

        #NOTE: i can write 'application.config' because there is 'attr_reader :config' in Application class
        @applications.delete_if { |application| SPF::Validate.conf? application.config}

      end

     
      def self.load_from_file(filename)
        # allow filename, string, and IO objects as input
        raise ArgumentError, "File #{filename} does not exist!" unless File.exist?(filename)

        Dir.glob(File.join(CONFIG_FOLDER,filename) do |conf|

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
end
