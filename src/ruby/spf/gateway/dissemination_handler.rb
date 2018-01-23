module SPF
  module Gateway

    class DisseminationHandler

      @@DEFAULT_APP_ID = 7843
      @@DEFAULT_POLLING_TIME = 60000
      @@DISSERVICE_DISSEMINATOR = 'DisService'
      @@DSPRO_DISSEMINATOR = 'DSPro'
      @@DEFAULT_DISSEMINATOR = @@DISSERVICE_DISSEMINATOR


      # Initialize a new AsyncDisseminationProxy from Java.
      #
      # @param app_id [Integer] The ID linked to the PIG application.
      # @param polling_interval [Integer] The polling interval in milliseconds.
      def initialize(app_id = @@DEFAULT_APP_ID, polling_interval = @@DEFAULT_POLLING_TIME, dissemination_type = @@DEFAULT_DISSEMINATOR)
        @dissemination_type = dissemination_type
        if @dissemination_type == @@DISSERVICE_DISSEMINATOR
		      @dissemination_handler = SPF::Gateway::DisServiceHandler.new(app_id, polling_interval)
	      elsif @dissemination_type == @@DSPRO_DISSEMINATOR
		      @dissemination_handler = SPF::Gateway::DSProHandler.new(app_id, polling_interval)
	      end
      end 

      # Suscribe is a DisService only directive
      #
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
        if @dissemination_type == @@DISSERVICE_DISSEMINATOR
          @dissemination_handler.subscribe(group_name, priority, group_reliable, message_reliable, sequenced)
        end
      end

      # Sends data to be pushed to Dissemination Service (DisService/DSPro)
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
      def push_message(group_name, obj_id, instance_id, mime_type, io, voi, expiration_time)
        if @dissemination_type == @@DISSERVICE_DISSEMINATOR
          @dissemination_handler.push_to_disservice(group_name, obj_id, instance_id, mime_type, io, voi, expiration_time)
        elsif @dissemination_type == @@DSPRO_DISSEMINATOR
          @dissemination_handler.add_message(group_name, obj_id, instance_id, mime_type, io, voi, expiration_time)          
      	end
      end

      def self.DEFAULT_APP_ID
        @@DEFAULT_APP_ID
      end

      def self.DEFAULT_POLLING_TIME
        @@DEFAULT_POLLING_TIME
      end

    end
  end
end
