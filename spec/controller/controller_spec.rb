require 'spec/spec_helper'
require 'spec/support/fake_socket'

require 'spf/common/exceptions'
require 'spf/controller/controller'

require_relative './reference_configuration'


describe SPF::Controller::Controller do

  it 'should call handle_connection upon a new connection request' do
    port = SPF::Controller::Controller::DEFAULT_REQUESTS_PORT

    # create temporary file with reference configuration
    tf = Tempfile.open('PIGS_CHARACTERIZATION')
    tf.write(PIGS_CHARACTERIZATION)
    tf.close

    controller = SPF::Controller::Controller.new("localhost", port, tf.path)

    # run the controller
    thread = Thread.new { controller.run(one_shot: true) }

    # wait for the controller to boot up
    # NOTE: sleep is highly unreliable for syncronization purposes! this code
    # needs to be changed to adopt a proper syncronization mechanism!
    sleep 2

    # connect to controller (no need to actually send data)
    socket = TCPSocket.new("localhost", port)
    socket.puts "REQUEST participants/find"
    socket.puts "User 3;44.838124,11.619786;find 'water'"
    socket.close
    # wait (at most 3 seconds) for the controller thread to exit
    thread.join(3)
    # delete temporary file
    tf.delete
    # release resources
    thread.kill
  end


  # it 'should implement a header read timeout' do
  #   # create a fake socket
  #   socket = FakeTCPSocket.new

  #   # send the socket to the controller
  #   lambda {
  #     @@controller.call_handle_connection(socket)
  #   }.must_raise(SPF::Common::Exceptions::HeaderReadTimeout)
  # end

  # it 'should complain if fed a wrong header' do
  #   # create a fake socket
  #   socket = FakeTCPSocket.new

  #   # prepare canned response
  #   socket.write("WRONG HEADER\nNOTHING VALUABLE HERE")

  #   # send the socket to the controller
  #   lambda {
  #     @@controller.call_handle_connection(socket)
  #   }.must_raise(SPF::Common::Exceptions::WrongHeaderFormatException)
  # end

  # it 'should implement a request read timeout' do
  #   # create a fake socket
  #   socket = FakeTCPSocket.new

  #   Thread.new do
  #     # prepare canned response
  #     socket.write("REPROGRAM 12345\nNOTHING VALUABLE HERE")

  #     # sleep 3 seconds (timeout is 2)
  #     sleep 3
  #   end

  #   # send the socket to the controller
  #   lambda {
  #     @@controller.call_handle_connection(socket)
  #   }.must_raise(SPF::Common::Exceptions::ProgramReadTimeout)
  # end

end
