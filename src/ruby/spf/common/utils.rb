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
    end
  end
end
