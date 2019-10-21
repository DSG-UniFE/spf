require 'java'
require 'thread'
require 'concurrent'

require 'spf/common/utils'
require 'spf/common/logger'


module SPF
  module Gateway
    class DataProcessor

    include Enumerable
    include SPF::Logging
    include SPF::Common::Utils

      def initialize(service_manager, benchmark, min_thread_size=2,
                      max_thread_size=2, max_queue_thread_size=0, queue_size=50)
        @service_manager = service_manager
        if benchmark.nil?
          @save_bench = false
        else
          @benchmark = benchmark
          @save_bench = true
        end
        @queue_size = queue_size
        @queue = Array.new
        @raw_data_index = Concurrent::AtomicFixnum.new
        @semaphore = Mutex.new
        @pool = Concurrent::ThreadPoolExecutor.new(
          min_threads: min_thread_size,
          max_threads: max_thread_size,
          max_queue: max_queue_thread_size
        )
      end

      def run
        loop do
          raw_data_index, raw_data, cam_id, gps, queue_time = pop
          if raw_data.nil? or cam_id.nil? or gps.nil?
            java.lang.System.gc
            sleep(1.0)
            next
          end

          @service_manager.with_pipelines_interested_in(raw_data) do |pl|
            loop do
              if @pool.remaining_capacity == 0
                sleep(0.1)
                next
              end
              begin
                @pool.post do
                  begin
                    puts "Processing data"
                    bench = pl.process(raw_data, cam_id, gps)
                    if @save_bench
                      unless bench.nil? or bench.empty?
                        duration = queue_time[:duration] + (queue_time[:stop] - queue_time[:start])
                        @benchmark[raw_data_index] = [bench, duration.to_s,
                                                      queue_time[:shift].to_s].flatten

                        # if @benchmark.length % 25
                        #   CSV.open("/tmp/pipeline.processing.time-#{Time.now}", "a",
                        #             :write_headers => true,
                        #             :headers => ["Pipeline ID", "Processing CPU time",
                        #                           "Processing time", "Filtering threshold",
                        #                           "Raw byte size", "Processed", "IO byte size",
                        #                           "Queue time"]) do |csv|
                        #     @benchmark.each { |res| csv << res }
                        #     @last_benchmark_saved += 25
                        #   end
                        # end
                      end
                    end
                    # process_memory = get_process_memory
                    # process_memory = (process_memory / 1024.0).round(2)
                    # logger.fatal "PROCESS MEMORY AFTER 'PROCESS': #{process_memory} MB"
                    # total, usage, free = get_memory
                    # logger.fatal "Total memory: #{total}; Used memory: #{usage}; Free memory: #{free}"
                  rescue => e
                    logger.error "*** #{self.class.name}: unexpected error, #{e.message} ***"
                    logger.error e.backtrace
                  ensure
                    raw_data = nil
                  end
                end
              rescue Concurrent::RejectedExecutionError
                logger.fatal "*** #{self.class.name}: fallback policy error, this error should not happen ***"
              ensure
                break
              end
            end
          end

        end
      end

      def each(&blk)
        @semaphore.synchronize { @queue.each(&blk) }
      end

      def pop
        raw_data_index, raw_data, cam_id, gps, queue_time = nil, nil, nil, nil, nil
        @semaphore.synchronize do
          raw_data_index, raw_data, cam_id, gps, queue_time = @queue.shift
          unless queue_time.nil?
            queue_time[:stop] = cpu_time if queue_time[:stop].nil?
          end
        end
        return raw_data_index, raw_data, cam_id, gps, queue_time
      end

      def push(raw_data, cam_id, gps)
        @semaphore.synchronize do
          @raw_data_index.increment
          queue_time = Hash.new
          queue_time[:start] = cpu_time
          queue_time[:stop] = nil
          queue_time[:shift] = false
          queue_time[:duration] = 0
          if @queue.length >= @queue_size
            tmp_raw_data_index, tmp_raw_data, _, _, tmp_queue_time = @queue.shift
            tmp_queue_time[:stop] = cpu_time
            tmp_queue_time[:shift] = true
            if @save_bench
              duration = tmp_queue_time[:duration] + (tmp_queue_time[:stop] - tmp_queue_time[:start])
              @benchmark[tmp_raw_data_index] = ["", "", "", "", tmp_raw_data.size.to_s,
                  "false", "", duration.to_s, tmp_queue_time[:shift].to_s].flatten
            end
            logger.warn "*** #{self.class.name}: Removed data from queue ***"
          end
          @queue.push([@raw_data_index.value, raw_data, cam_id, gps, queue_time])
          # logger.warn "*** #{self.class.name}: PUSH @queue.length: #{@queue.length} ***"
        end
      end

      def to_a
        @semaphore.synchronize { @queue.to_a }
      end

      def <<(raw_data, cam_id, gps)
        push(raw_data, cam_id, gps)
      end

      private

        def push_head(raw_data, cam_id, gps, queue_time)
          @semaphore.synchronize do
            if @queue.length >= @queue_size
              tmp_raw_data_index, tmp_raw_data, _, _, tmp_queue_time = @queue.shift
              tmp_queue_time[:stop] = cpu_time
              tmp_queue_time[:shift] = true
              if @save_bench
                duration = tmp_queue_time[:duration] + (tmp_queue_time[:stop] - tmp_queue_time[:start])
                @benchmark[tmp_raw_data_index] = ["", "", "", "", tmp_raw_data.size.to_s,
                    "false", "", duration.to_s, tmp_queue_time[:shift].to_s].flatten
              end
              logger.warn "*** #{self.class.name}: Removed data from queue ***"
            end
            @raw_data_index.increment
            queue_time[:stop] = cpu_time
            queue_time[:duration] += (queue_time[:stop] - queue_time[:start])
            queue_time[:start] = cpu_time
            @queue.unshift([raw_data_index, raw_data, cam_id, gps, queue_time])
          end
        end
    end
  end
end
