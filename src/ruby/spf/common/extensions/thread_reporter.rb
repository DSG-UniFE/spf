class << Thread
  alias old_new new

  def new(*args, &block)
    old_new(*args) do |*bargs|
      begin
        block.call(*bargs)
      rescue Exception => e
        raise if Thread.abort_on_exception || Thread.current.abort_on_exception
        puts "Thread for block #{block.inspect} terminated with exception: #{e.message}"
        puts e.backtrace.map {|line| "  #{line}"}
      end
    end
  end

end
