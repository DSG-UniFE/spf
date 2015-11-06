require 'timeout'

require 'spf/common/controller'


module SPF
  module Gateway
    class Controller < SPF::Common::Controller
      # timeouts
      DEFAULT_OPTIONS = {
        header_read_timeout:  10,     # 10 seconds
        program_read_timeout: 2 * 60, # 2 minutes
      }
      class HeaderReadTimeout < Exception; end
      class ProgramReadTimeout < Exception; end

      # Get ASCII/UTF-8 code for newline character
      # Note: the following code is uglier but should be more portable and
      # robust than a simple '\n'.ord
      NEWLINE = '\n'.unpack('C').first

      def initialize(host, port, opts = {})
        super(host, port)
        @conf = DEFAULT_OPTIONS.merge(opts)
      end

      private

        def handle_connection(socket)
          # get client address
          _, port, host = socket.peeraddr
          logger.info "*** Received connection from #{host}:#{port} ***"

          # try to read first line
          buffer = []
          status = Timeout::timeout(@conf[:header_read_timeout],
                                    HeaderReadTimeout) do
            loop do
              buffer << socket.readpartial(4096)
              newline_index = buffer.find_index(NEWLINE)
              break if newline_index
            end
          end

          # retrieve first line
          first_line = buffer.shift(newline_index) \  # get the bytes
                             .pack('C*')           \  # convert them to characters
                             .force_encoding('utf-8') # UTF-8 encoding

          # drop newline
          buffer.shift

          # parse (tokenize, actually) the header line
          header = first_line.split(" ")

          # check header format, which should be "PROGRAM size_in_bytes"
          unless header.size == 2 and header.first == "PROGRAM"
            raise WrongHeaderFormatException
          end

          # obtain number of bytes to read
          to_read = Integer(program_size) # might raise ArgumentError

          # read actual program
          status = Timeout::timeout(@conf[:program_read_timeout],
                                    ProgramReadTimeout) do
            loop do
              buffer << socket.readpartial(4096)
              break if buffer.size >= to_read
            end
          end

          # retrieve first line
          program = buffer.shift(to_read) \        # get the bytes
                          .pack('C*')     \        # convert them to characters
                          .force_encoding('utf-8') # UTF-8 encoding

          # reset configuration
          # TODO: this is just a placeholder
          Configuration.reset(program)

        rescue HeaderReadTimeout
          logger.warn  "*** Timeout reading header from #{host}:#{port}! ***"
        rescue ProgramReadTimeout
          logger.warn  "*** Timeout reading program from #{host}:#{port}! ***"
        rescue WrongHeaderFormatException
          logger.error "*** Received header with wrong format from #{host}:#{port}! ***"
        rescue ArgumentError
          logger.error "*** #{host}:#{port} sent wrong program size format! ***"
        rescue EOFError
          logger.error "*** #{host}:#{port} disconnected! ***"
        ensure
          socket.close
        end
    end
  end
end
