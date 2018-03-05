module SPF
  module Common
    module Utils
      def cpu_time
        if Process.const_defined? :CLOCK_PROCESS_CPUTIME_ID
          Process.clock_gettime(Process::CLOCK_PROCESS_CPUTIME_ID, :microsecond)
        elsif Process.const_defined? :GETRUSAGE_BASED_CLOCK_PROCESS_CPUTIME_ID
          Process.clock_gettime(Process::GETRUSAGE_BASED_CLOCK_PROCESS_CPUTIME_ID, :microsecond)
        elsif Process.const_defined? :TIMES_BASED_CLOCK_PROCESS_CPUTIME_ID
          Process.clock_gettime(Process::TIMES_BASED_CLOCK_PROCESS_CPUTIME_ID, :microsecond)
        elsif Process.const_defined? :CLOCK_BASED_CLOCK_PROCESS_CPUTIME_ID
          Process.clock_gettime(Process::CLOCK_BASED_CLOCK_PROCESS_CPUTIME_ID, :microsecond)
        else
          Process.clock_gettime(Process::CLOCK_MONOTONIC, :microsecond)
        end
      end

      def wall_time
        Process.clock_gettime(Process::CLOCK_MONOTONIC, :microsecond)
      end

      def get_process_memory
        `ps -o rss= -p #{Process.pid}`.to_i
      end

      def get_memory
        memory = %x(free -h)
        total = memory.split(" ")[7]
        usage = memory.split(" ")[8]
        free = memory.split(" ")[9]
        [total, usage, free]
      end

      def camelize(string)
        # "hello_world" => "HelloWorld"
        string.split('_').collect(&:capitalize).join
      end

    end
  end
end
