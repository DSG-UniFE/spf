module SPF
  module Common
    module Exceptions
      class NilParameterException < Exception; end
      class ArgumentException < Exception; end
      class OutOfRangeException < Exception; end
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
      class WrongSystemCommandException < Exception; end
      class WrongRawDataHeaderException < Exception; end
      class WrongRawDataReadingException < Exception; end
    end
  end
end
