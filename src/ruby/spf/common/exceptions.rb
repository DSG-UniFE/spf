module SPF
  module Common
    module Exceptions
      class HeaderReadTimeout < Exception; end
      class PigConnectTimeout < Exception; end
      class ReceiveRequestTimeout < Exception; end
      class ProgramReadTimeout < Exception; end
      class WrongHeaderFormatException < Exception; end
    end
  end
end
