require 'socket'
require 'gateway/pig'


# this class aims at faking a request from the SPF controller to a PIG (more
# specifically, to the controller component of the PIG)

class ServiceRequest < Minitest::Benchmark

    def setup()
      #TODO: launch PIG
    end

    def run
      # send a request and wait for remote answer
      begin
        pig_socket = TCPSocket.new(localhost, SPF::PIG::DEFAULT_PROGRAMMING_PORTport)
      rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
        raise "Connection to host #{host}:#{port} failed"
      end
      answer = ""

      # TODO: use benchmarking
      start_time = Time.now
      pig_socket.write(@content)
      while line = s.gets
        answer += line
      end
      finish_time = Time.now

      puts "Time to answer request <#{@content}>: #{finish_time - start_time}"
    ensure
      @pig_socket.close
    end

end
