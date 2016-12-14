require 'set'
require 'concurrent'

module SPF
  module Gateway
    class Pipeline

      # Check on matching message type is handled at the processing stragegy level.
      extend Forwardable
      def_delegator :@processing_strategy, :interested_in?

      def initialize(processing_strategy)
        # keep track of last piece of raw data that was "sieved, processed, and
        # forwarded"
        @last_raw_data_spfd = {}

        # lock to protect access to last_raw_data_spfd variable
        @last_raw_data_spfd_lock = Concurrent::ReadWriteLock.new

        # keep track of services that leverage this pipeline
        @services = Set.new
        @services_lock = Mutex.new

        @processing_strategy = processing_strategy
        # TODO: should we postpone the processing strategy activation?
        @processing_strategy.activate
      end

      def has_services?
        @services_lock.synchronize do
          !@services.empty?
        end
      end

      def register_service(svc)
        @services_lock.synchronize do
          @services.add(svc)
          @processing_threshold = find_min_tau
        end
      end

      def unregister_service(svc)
        return unless @services.include?(svc)

        @services_lock.synchronize do
          @services.delete(svc)
          if @services.empty?
            @processing_strategy.deactivate
          end
          @processing_threshold = find_min_tau
        end
      end

      def process(raw_data, source)
        # 1) "sieve" the data
        # calculate amount of new information with respect to previous messages
        @last_raw_data_spfd_lock.with_read_lock do
          delta = @processing_strategy.information_diff(raw_data, @last_raw_data_spfd[source.to_sym])
        end

        # ensure that the delta passes the processing threshold
        return nil if delta < @processing_threshold

        # update last_raw_data
        @last_raw_data_spfd_lock.with_write_lock do
          # recheck the state because another thread might have acquired
          # the write lock and changed last_raw_data before we have
          delta = @processing_strategy.information_diff(raw_data, @last_raw_data_spfd[source.to_sym])
          return nil if delta < @processing_threshold

          # actually update last_raw_data
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

      private

        # Find minimum tau among current active services' taus.
        def find_min_tau
          taus = []
          @services.each do |svc|
            taus += [svc.tau]
          end
          taus.min
        end

    end
  end
end
