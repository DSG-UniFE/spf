require 'java'
require 'concurrent'

require 'spf/common/logger'

java_import 'us.ihmc.aci.dspro2.AsyncDSProProxy'

module SPF
  module Gateway

    class DSProHandler

      include SPF::Logging

      # Initialize a new AsyncDSProProxy from Java.
      #
      # @param app_id [Integer] The ID linked to the PIG application.
      # @param polling_interval [Integer] The polling interval in milliseconds.
      def initialize(app_id, polling_interval)
        @handler = AsyncDSProProxy.new(app_id.to_java(:short), polling_interval.to_java(:long))
        begin
          rc = @handler.init
          if rc != 0
            logger.error "*** #{self.class.name}: DSProProxy init failed - proxy down? ***"
          end
          t = Java::JavaLang::Thread.new { @handler.run }
          t.start
        rescue java.net.ConnectException => e
          logger.error "*** #{self.class.name}: unable to connect to the DSProProxy instance - proxy down? ***"
        rescue us.ihmc.comm.CommException => e
            logger.error "*** #{self.class.name}: CommException during the connection to the DSProProxy instance - proxy down? ***"
        rescue => e
          logger.error "*** #{self.class.name}: unknown error when trying to connect to the DSProProxy instance ***"
        end
      end

      #TO-DO decide how to build the Metadata

      # Add a message using DSPro.
      #
      # @param group_name [String] The group of the message.
      # @param obj_id [String] ID of the IO within the application system
      #   (e.g., the request ID?).
      # @param instance_id [String] Expresses other versions of the IO with the
      #   obj_id as ID (e.g., to manage updates).
      # @param io [Array] The IO to disseminate (data).
      # @param expiration_time [Integer] Time (in milliseconds) before the IO expires.
      # @param source [Hash] GPS coordinates that will be used in the DSPro matchmaking 
      # the IO should contain information regarding the source location, or do we need another fiedl
      def add_message(group_name, obj_id, instance_id, mime_type, io, expiration_time, source)
        metadata = {:Left_Upper_Latitude => source[:lat], :Right_Lower_Longitude => source[:lon], 
        :Right_Lower_Latitude => source[:lat], :Left_Upper_Longitude => source[:lon], :Data_format => mime_type }
        #Build the metadata
        @handler.addMessage(group_name, obj_id, instance_id, metadata.to_java, io.to_java_bytes, expiration_time)
        logger.info "*** #{self.class.name}: pushed an IO of #{io.bytesize} bytes to DSPro ***"
      end

    end
  end
end
