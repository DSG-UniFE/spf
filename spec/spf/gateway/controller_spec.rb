require 'spec/spec_helper'
require 'spec/support/fake_socket'

require 'spf/gateway/controller'


describe SPF::Gateway::Controller do
  before do
    # try to create a controller
    attempts = 5
    port = SPF::Common::Controller::DEFAULT_PROGRAMMING_PORT
    begin
      @@controller = SPF::Gateway::Controller.new("localhost", port
                                                  header_read_timeout: 1,
                                                  program_read_timeout: 1)
    rescue
      attempts -= 1
      port += 1
      attempts > 0 ? retry : fail
    end

    # add method faking connection arrival
    def @@controller.fake_connection_arrival(s)
      Thread.new { handle_connection(s) }
    end
  end


  it 'should implement a header read timeout' do
    # create a fake socket
    socket = FakeTCPSocket.new

    # prepare canned response
    socket.set_canned('NOTHING VALUABLE HERE')

    # sleep 2 seconds (timeout is 1)
    sleep 2

    # send the socket to the controller
    @@controller.fake_connection_arrival(socket).must_raise
      SPF::Gateway::Controller::HeaderReadTimeout
  end

  it 'should timeout when the header is not read' do
    # create a fake socket
    socket = FakeTCPSocket.new

    # prepare canned response
    socket.set_canned("WRONG HEADER\nNOTHING VALUABLE HERE")

    # send the socket to the controller
    @@controller.fake_connection_arrival(socket).must_raise
      SPF::Gateway::Controller::WrongHeaderFormatException
  end

  it 'should implement a request read timeout' do
    # create a fake socket
    socket = FakeTCPSocket.new

    # prepare canned response
    socket.set_canned("PROGRAM 12345\nNOTHING VALUABLE HERE")

    # sleep 3 seconds (timeout is 2)
    sleep 3

    # send the socket to the controller
    @@controller.fake_connection_arrival(socket).must_raise
      SPF::Gateway::Controller::ProgramReadTimeout
  end

end
