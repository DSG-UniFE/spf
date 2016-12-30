require 'java'
require 'spf/common/logger'

java_import 'us.ihmc.aci.disServiceProxy.AsyncDisseminationServiceProxy'


module SPF
  module Gateway
    
    class DisServiceHandler
      
      include SPF::Logging

      @@DEFAULT_APP_ID = 7843
      @@DEFAULT_POLLING_TIME = 60000

      # Initialize a new AsyncDisseminationServiceProxy from Java.
      #
      # @param app_id [Integer] The ID linked to the PIG application.
      # @param polling_interval [Integer] The polling interval in milliseconds.
      def initialize(app_id = @@DEFAULT_APP_ID, polling_interval = @@DEFAULT_POLLING_TIME)
        @handler = AsyncDisseminationServiceProxy.new(app_id.to_java(:short), polling_interval.to_java(:long))
        @handler.init
      end

      # Sends data to be pushed to DisService.
      #
      # @param group_name [String] The name of the DisService group within which
      #   IO dissemination will take place.
      # @param obj_id [String] ID of the IO within the application system
      #   (e.g., the request ID?).
      # @param instance_id [String] Expresses other versions of the IO with the 
      #   obj_id as ID (e.g., to manage updates).
      # @param mime_type [String] The MIME type of the IO.
      # @param io [Array] The IO to disseminate.
      # @param voi [Float] VoI parameter (between 0.0 and 100.0) for the IO to disseminate.
      # @param expiration_time [Integer] Time (in milliseconds) before the IO expires.
      def push_to_disservice(group_name, obj_id, instance_id, mime_type, io, voi, expiration_time)
        voi = ((voi / 100.0) * 255).round
        puts "#{voi}"
        @handler.push(group_name, obj_id, instance_id, mime_type, nil, io.to_java_bytes, expiration_time,
          0.to_java(:short), 0.to_java(:short), voi.to_java(:byte))
        logger.info "*** PIG: pushed an IO of #{io.bytesize} bytes to DisService ***"
      end
      
    end
  end
end