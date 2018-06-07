require 'java'
require 'spf/common/logger'

java_import 'us.ihmc.aci.disServiceProxy.AsyncDisseminationServiceProxy'


module SPF
  module Gateway

    class DisServiceHandler

      include SPF::Logging

      # Initialize a new AsyncDisseminationServiceProxy from Java.
      #
      # @param app_id [Integer] The ID linked to the PIG application.
      # @param polling_interval [Integer] The polling interval in milliseconds.
      def initialize(app_id, address, port, polling_interval)
        @handler = AsyncDisseminationServiceProxy.new(app_id.to_java(:short), address, port.to_java(:int), polling_interval.to_java(:long))
        begin
          @handler.init
        rescue java.net.ConnectException => e
          logger.error "*** #{self.class.name}: unable to connect to the DisServiceProxy instance - proxy down? ***"
        rescue => e
          logger.error "*** #{self.class.name}: unknown error when trying to connect to the DisServiceProxy instance ***"
        end
      end
      
      # Subscribes the node to the application-specific DisService group.
      #
      # @param group_name [String] The name of the DisService group within which
      #                            IO dissemination will take place.
      # @param priority [Integer] priority value in the range 0-255.
      # @param group_reliable [Boolean] if true, all messages after the first one received  
      #                                 will be delivered to the subscribing application.
      # @param message_reliable [Boolean] if true, any missing message fragments will be   
      #                                   requested from peers.
      # @param sequenced [Boolean] if true, messages will be delivered in order to the
      #                            subscribing application
      def subscribe(group_name, priority = 1, group_reliable = true, message_reliable = true, sequenced = false)
        @handler.subscribe(group_name, priority.to_java(:byte), group_reliable.to_java(:boolean),
                           message_reliable.to_java(:boolean), sequenced.to_java(:boolean))
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
        @handler.push(group_name, obj_id, instance_id, mime_type, nil, io.to_java_bytes, expiration_time,
                      0.to_java(:short), 0.to_java(:short), voi.to_java(:byte))
        logger.info "*** #{self.class.name}: pushed an IO of #{io.bytesize} bytes to DisService ***"
      end

    end
  end
end
