require 'set'
require 'thread'
require 'concurrent'

require 'spf/common/utils'
require 'spf/common/logger'


module SPF
  module Gateway
    class Pipeline

      include SPF::Logging
      include SPF::Common::Utils

      # Check on matching message type is handled at the processing stragegy level.
      extend Forwardable

      def_delegator :@processing_strategy, :get_pipeline_id

      def initialize(processing_strategy, tau_test)
        # For each sensor, the pipeline needs to keep track of the latest
        # piece of raw data that was "Sieved, Processed, and Forwarded"
        @last_raw_data_spfd = {}
        @last_processed_data_spfd = {}
        @last_raw_data_spfd_lock = Concurrent::ReadWriteLock.new    # lock for the last_raw_data_spfd variable

        # keep track of services that leverage this pipeline
        @services = Set.new
        @services_lock = Concurrent::ReadWriteLock.new

        @processing_strategy = processing_strategy
        # TODO: should we postpone the processing strategy activation?
        @processing_strategy.activate

        # For tests
        @tau_test = tau_test
        unless @tau_test.nil?
          @semaphore = Mutex.new
          @process_counter = 0
          @threshold_position = nil
        end
      end

      def tau_updated
        @processing_threshold = find_min_tau
      end

      def has_service?(svc)
        @services_lock.with_read_lock do
          return @services.include?(svc)
        end
      end

      def has_services?
        @services_lock.with_read_lock do
          !@services.empty?
        end
      end

      def register_service(svc)
        return if @services.include?(svc)

        @services_lock.with_write_lock do
          @services.add(svc)
          @processing_threshold = find_min_tau
        end
      end

      def unregister_service(svc)
        return unless @services.include?(svc)

        @services_lock.with_write_lock do
          @services.delete(svc)
          if @services.empty?
            @processing_strategy.deactivate
          end
          @processing_threshold = find_min_tau
        end
      end

      def interested_in?(raw_data)
        type = SPF::Gateway::FileTypeIdentifier.identify(raw_data)
        return false unless @processing_strategy.interested_in?(type)

        # check with registered services if computation is requested
        with_registered_services do |svc|
          return true if !svc.on_demand || svc.has_requests_for_pipeline(@processing_strategy.get_pipeline_id)
        end

        false
      end

      def process(raw_data, cam_id, source)
        # For tests
        unless @tau_test.nil?
          @semaphore.synchronize do
            if @threshold_position.nil?
              @processing_threshold = @tau_test[:tau_vals][0]
              @threshold_position = 0
            end
            if @process_counter % @tau_test[:process_num] == 0
              if @threshold_position < @tau_test[:tau_vals].length
                @processing_threshold = @tau_test[:tau_vals][@threshold_position]
                @threshold_position += 1
              else
                @processing_threshold = @tau_test[:tau_vals][-1]
              end
            end
            @process_counter += 1
            # puts "@process_counter: #{@process_counter}"
            # puts "@threshold_position: #{@threshold_position}"
            # puts "@processing_threshold: #{@processing_threshold}"
          end
        end

        cpu_start_time, cpu_stop_time = nil
        wall_start_time, wall_stop_time = nil
        # 1) "sieve" the data
        # calculate amount of new information with respect to previous messages
        cpu_start_time, wall_start_time = cpu_time, wall_time
        delta = 0.0;
        @last_raw_data_spfd_lock.with_read_lock do
          delta = @processing_strategy.information_diff(raw_data, @last_raw_data_spfd[cam_id])

          # ensure that the delta passes the processing threshold
          if delta < @processing_threshold
            cpu_stop_time, wall_stop_time = cpu_time, wall_time
            logger.info "*** #{self.class.name}: delta value #{delta} is lower than the threshold (#{@processing_threshold}) ***"

            # Cached IO is still valid --> services can use it
            @services_lock.with_read_lock do
              @services.each do |svc|
                svc.new_information(@last_processed_data_spfd[cam_id], source, @processing_strategy.get_pipeline_id)
              end
            end

            benchmark = [get_pipeline_id.to_s,
                          (cpu_stop_time - cpu_start_time).to_s,
                          (wall_stop_time - wall_start_time).to_s,
                          @processing_threshold.to_s,
                          raw_data.size.to_s,
                          "false",
                          @last_processed_data_spfd[cam_id].size.to_s]

            return benchmark
          end
        end

        # update last_raw_data and last_processed_data_spfd
        @last_raw_data_spfd_lock.with_write_lock do
          # recheck the state because another thread might have acquired
          # the write lock and changed last_raw_data before we have
          delta = @processing_strategy.information_diff(raw_data, @last_raw_data_spfd[cam_id])
          if delta < @processing_threshold
            cpu_stop_time, wall_stop_time = cpu_time, wall_time
            logger.info "*** #{self.class.name}: delta value #{delta} is lower than the threshold (#{@processing_threshold}) ***"

            # Cached IO is still valid --> services can use it
            @services_lock.with_read_lock do
              @services.each do |svc|
                svc.new_information(@last_processed_data_spfd[cam_id], source, @processing_strategy.get_pipeline_id)
              end
            end

            benchmark = [get_pipeline_id.to_s,
                          (cpu_stop_time - cpu_start_time).to_s,
                          (wall_stop_time - wall_start_time).to_s,
                          @processing_threshold.to_s,
                          raw_data.size.to_s,
                          "false",
                          @last_processed_data_spfd[cam_id].size.to_s]

            return benchmark
          end

          cpu_stop_time, wall_stop_time = nil, nil
          # 2) "process" the raw data and cache the resulting IO
          begin
            @last_processed_data_spfd[cam_id] = @processing_strategy.do_process(raw_data)
            cpu_stop_time, wall_stop_time = cpu_time, wall_time

            # update and cache last_raw_data
            @last_raw_data_spfd[cam_id] = raw_data
          rescue SPF::Common::Exceptions::WrongSystemCommandException => e
            logger.error e.message
            return
          end

          # 3) "forward" the information object
          @services_lock.with_read_lock do
            @services.each do |svc|
              svc.new_information(@last_processed_data_spfd[cam_id], source, @processing_strategy.get_pipeline_id)
            end
          end

          benchmark = [get_pipeline_id.to_s,
                        (cpu_stop_time - cpu_start_time).to_s,
                        (wall_stop_time - wall_start_time).to_s,
                        @processing_threshold.to_s,
                        raw_data.size.to_s,
                        "true",
                        @last_processed_data_spfd[cam_id].size.to_s]

          return benchmark
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

        def with_registered_services
          @services_lock.with_read_lock do
            @services.each do |svc|
              yield svc
            end
          end
        end

    end
  end
end
