require 'socket'
require 'spec/spec_helper'
require 'spf/common/controller'


# this is a helper class used to test that the SPF::Common::Controller
# actually calls the handle_connection method
class MyController < SPF::Common::Controller
  attr_reader :calls

  def initialize(host,port)
    super(host,port)
    @calls = 0
  end

  private
    def handle_connection(socket)
      @calls += 1
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
      thr = Thread.new { controller.run }

      # connect to controller (no need to actually send data)
      socket = TCPSocket.new("localhost", port)

      # check that handle_connection was actually called
      controller.calls.must_equal 1
    ensure
      # release resources
      thr.kill
      socket.close
    end
  end

end
