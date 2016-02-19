require 'thread'

class FakeTCPSocket

  def initialize()
    @incoming_message_queue = []
    @lock = Mutex.new
    @queue_not_empty_cv = ConditionVariable.new
  end

  def gets
    line = ""
    have_entire_line = false

    @lock.synchronize do
      until have_entire_line do
        # wait for incoming messages if none has been received yet
        @queue_not_empty_cv.wait(@lock) if @incoming_message_queue.empty?

        # get first message
        msg = @incoming_message_queue.pop

        if idx = msg.index(/\n/)
          # we have a newline character at index idx
          line += msg.slice!(0..idx)

          # we have an entire line now
          have_entire_line = true

          # if there are leftover data ...
          unless msg.empty?
            # ... put them back in the incoming message queue
            @incoming_message_queue.unshift msg

            # ... and notify the incoming message queue has data available
            @queue_not_empty_cv.signal
          end
        end
      end

      line
    end
  end

  def flush
  end

  def readpartial(num)
    @lock.synchronize do
      # wait for incoming messages if none has been received yet
      @queue_not_empty_cv.wait(@lock) if @incoming_message_queue.empty?

      # get first message
      msg = @incoming_message_queue.pop

      # get at most num elements (bytes or characters)
      # (NOTE: readpartial should return at most num bytes, but for testing
      # purposes this should be ok)
      if num > msg.size
        return msg
      else
        # get the first num elements (bytes or characters)
        ret = msg.slice!(0...num)

        # put back leftover data in the incoming message queue ...
        @incoming_message_queue.unshift msg
        # ... and notify the incoming message queue has data available
        @queue_not_empty_cv.signal

        return ret
      end
    end
  end

  def write(msg)
    @lock.synchronize do
      # add message to the incoming message queue
      @incoming_message_queue << msg
      # notify there are data availabled in the incoming message queue
      @queue_not_empty_cv.signal
    end
  end

  def close
    # noop
  end

  FAMILIES = %q{AF_INET AF_INET6}
  IP_ADDRESSES = %q{127.0.0.1 ::1}

  def peeraddr
    # return a partially-random peer address
    idx = rand(FAMILIES.size)
    [ FAMILIES[idx], rand(65536), "localhost", IP_ADDRESSES[idx] ]
  end
end


# class FakeUDPSocket

#   def flush
#   end

#   def write(some_text = nil)
#   end

#   def read(num)
#     return num > @incoming_message_queue.size ? @incoming_message_queue : @incoming_message_queue[0..num]
#   end

#   def set_canned(response)
#     @incoming_message_queue = response
#   end

# end
