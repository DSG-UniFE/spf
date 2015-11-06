require 'socket'
require 'concurrent'

module SPF
  module Gateway
    class Processor
      def initialize(host, port)
        @host = host; @port = port

        # We adopt a thread pool architecture because it should use multi-core
        # CPU architectures more efficiently. Also, cached thread pools are
        # supposed to work very well with short processing tasks.
        @pool = Concurrent::CachedThreadPool.new
      end

      def run
        puts "*** Starting processing endpoint on #{@host}:#{@port} ***"

        Socket.udp_server_loop(@port) do |msg, source|
          # source is a UDPSource object
          # source.reply msg
          @pool.post do
            process_message(msg)
          end
        end
      end

      private

        def process_message(msg)
          Configuration::with_services_interested_in(msg) do |svc|
            # get application and processing pipeline
            app = svc.application
            pp  = svc.processing_pipeline(msg) # services might share pipelines

            # calculate amount of new information with respect to previous messages
            delta = pp.new_information

            # ensure that the delta passes the processing threshold
            next if delta < pp.processing_threshold

            # calculate voi
            voi = calculate_max_voi(msg, app, svc.closest_recipient, svc.most_recent_request)

            # do the actual processing
            processed_msg = pp.process(msg, voi)
          end
        end
  end
end
