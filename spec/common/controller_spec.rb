require 'socket'
require 'concurrent'
require 'spec/spec_helper'
require 'spf-common/controller'


# this is a helper class used to test that the SPF::Common::Controller
# actually calls the handle_connection method
class MyController < SPF::Common::Controller
  def initialize(host,port)
    super(host,port)
    @calls = Concurrent::AtomicFixnum.new(0)
  end

  def calls
    @calls.value
  end

  private
    def handle_connection(socket)
      @calls.increment
      socket.gets
      socket.close
    end
end


describe SPF::Common::Controller do

  it 'should call handle_connection upon a new connection request' do
    # try to create a controller
    attempts = 5
    port = SPF::Common::Controller::DEFAULT_PROGRAMMING_PORT
    begin
      controller = MyController.new("localhost", port)
    rescue
      attempts -= 1
      port += 1
      attempts > 0 ? retry : fail
    end

    begin
      # run the controller
      thr = Thread.new { controller.run(one_shot: true) }

      # wait for the controller to boot up
      # NOTE: sleep is highly unreliable for syncronization purposes! this code
      # needs to be changed to adopt a proper syncronization mechanism!
      sleep 1

      # connect to controller (no need to actually send data)
      socket = TCPSocket.new("localhost", port)
      socket.puts "something"
      socket.close

      # wait (at most 3 seconds) for the controller thread to exit
      thr.join(3)

      # check that handle_connection was actually called
      controller.calls.must_equal 1
    ensure
      # release resources
      thr.kill
      socket.close
    end
  end

end
