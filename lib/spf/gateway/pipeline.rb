require 'concurrent'

module SPF
  module Gateway
    class Pipeline

      # Check on matching message type is handled at the processing stragegy level.
      extend Forwardable
      def_delegator :@processing_strategy, :interested_in?

      def initialize(threshold, processing_strategy)
        @processing_threshold = threshold.try(:to_f)
        raise ArgumentError unless @processing_threshold

        # keep track of last piece of raw data that was "sieved, processed, and
        # forwarded"
        @last_raw_data_spfd = {}

        # lock to protect access to last_raw_data_spfd variable
        @last_raw_data_spfd_lock = Concurrent::ReadWriteLock.new

        # keep track of services that leverage this pipeline
        @services = Set.new
        @services_lock = Mutex.new

        @processing_strategy = processing_strategy
      end

      def register_service(svc)
        @services_lock.synchronize do
          @services.add(svc)
        end
      end

      def unregister_service(svc)
        have_services = true

        @services_lock.synchronize do
          @services.delete(svc)
          have_services = !@services.empty?
        end

        # TODO: if last service was unregister, deactivate pipeline
        if !have_services
          @processing_strategy.deactivate
        end
      end

      def process(raw_data, source)
        # 1) "sieve" the data
        # calculate amount of new information with respect to previous messages
        @last_raw_data_spfd_lock.with_read_lock do
          delta = @processing_strategy.new_information(raw_data, @last_raw_data_spfd[source.to_sym])
        end

        # ensure that the delta passes the processing threshold
        return nil if delta < @processing_threshold

        # update last_raw_data_sent
        @last_raw_data_spfd_lock.with_write_lock do
          @last_raw_data_spfd[source.to_sym] = raw_data
        end

        # 2) "process" the raw data
        io = @processing_strategy.do_process(raw_data)

        # 3) "forward" the information object
        @services_lock.synchronize do
          @services.each do |svc|
            svc.new_information(io, source)
          end
        end
      end

    end
  end
end
