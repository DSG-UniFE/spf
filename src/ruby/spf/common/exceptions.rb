module SPF
  module Common
    module Exceptions
      class ConfigurationError < Exception; end
      class HeaderReadTimeout < Exception; end
      class PigConnectTimeout < Exception; end
      class UnreachablePig < Exception; end
      class ReceiveRequestTimeout < Exception; end
      class ProgramReadTimeout < Exception; end
      class WrongHeaderFormatException < Exception; end
      class WrongBodyFormatException < Exception; end
      class WrongServiceRequestStringFormatException < Exception; end
      class PipelineNotActiveException < Exception; end
    end
  end
end
