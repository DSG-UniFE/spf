require 'logger'

module SPF
  module Logging
    class << self
      def logger
        @logger ||= ::Logger.new(STDERR)
        @logger.level = ::Logger::INFO
        @logger
      end
    end

    def self.included(base)
      class << base
        # this version of the logger method will be called from class methods
        def logger
          Logging.logger
        end
      end
    end

    # this version of the logger method will be called from instance methods
    def logger
      Logging.logger
    end
  end
end
