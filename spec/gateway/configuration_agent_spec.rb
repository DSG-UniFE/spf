require 'spec/spec_helper'
require 'spec/support/fake_socket'

require 'spf/common/exceptions'
require 'spf/gateway/pig'
require 'spf/gateway/configuration_agent'
require 'spf/gateway/service_manager'


describe SPF::Gateway::ConfigurationAgent do
  before do
    # try to create a controller
    attempts = 5
    port = SPF::Gateway::PIG::DEFAULT_PROGRAMMING_PORT
    puts "#{port}"
    begin
      @@controller = SPF::Gateway::ConfigurationAgent.new(SPF::Gateway::ServiceManager.new,
                                                          "localhost", port,
                                                          header_read_timeout: 2,
                                                          program_read_timeout: 2)
    rescue
      attempts -= 1
      port += 1
      attempts > 0 ? retry : fail
    end

    # helper method that bypasses privateness of handle_connection and allow
    # the test code to invoke it
    def @@controller.call_handle_connection(s)
      handle_connection(s)
    end
  end


  it 'should implement a header read timeout' do
    # create a fake socket
    socket = FakeTCPSocket.new

    # send the socket to the controller
    lambda {
      @@controller.call_handle_connection(socket)
    }.must_raise(SPF::Common::Exceptions::HeaderReadTimeout)
  end

  it 'should complain if fed a wrong header' do
    # create a fake socket
    socket = FakeTCPSocket.new

    # prepare canned response
    socket.write("WRONG HEADER\nNOTHING VALUABLE HERE")

    # send the socket to the controller
    lambda {
      @@controller.call_handle_connection(socket)
    }.must_raise(SPF::Common::Exceptions::WrongHeaderFormatException)
  end

  it 'should implement a request read timeout' do
    # create a fake socket
    socket = FakeTCPSocket.new

    Thread.new do
      # prepare canned response
      socket.write("REPROGRAM 12345\nNOTHING VALUABLE HERE")

      # sleep 3 seconds (timeout is 2)
      sleep 3
    end

    # send the socket to the controller
    lambda {
      @@controller.call_handle_connection(socket)
    }.must_raise(SPF::Common::Exceptions::ProgramReadTimeout)
  end

end
