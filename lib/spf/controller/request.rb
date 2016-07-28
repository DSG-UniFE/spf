require 'socket'
require 'spf/logger'

module SPF
  class Request
    include SPF::Logging

    DEFAULT_PROGRAMMING_PORT = 52160

    def initialize(host, port = DEFAULT_PROGRAMMING_PORT, request)
      # open a TCPServer as programming endpoint
      logger.info "*** Starting request thread for request #{request} to PIG #{host}:#{port} ***"
      @pig_socket = TCPSocket.new(host, port)
      rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
        raise "Connection to host #{host}:#{port} failed"
      end
      @request = request
    end

    def run()
      # send a request and wait for remote answer
      answer = ""
      start_time = Time.now
      @pig_socket.write(@request)
      while line = s.gets
        answer += line
      end
      finish_time = Time.now
      
      puts "Time to answer request <#{@request}>: #{finish_time - start_time}"
    ensure
      @pig_socket.close
    end
    
  end
end
