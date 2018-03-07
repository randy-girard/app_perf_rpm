# frozen_string_literal: true

require 'logger'

module AppPerfRpm
  class << self
    attr_accessor :logger
  end

  class Logger
    def info(msg)
      AppPerfRpm.info(msg)
    end

    def debug(msg)
      AppPerfRpm.info(msg)
    end

    def warn(msg)
      AppPerfRpm.info(msg)
    end

    def error(msg)
      AppPerfRpm.info(msg)
    end

    def fatal(msg)
      AppPerfRpm.info(msg)
    end
  end
end

AppPerfRpm.logger = Logger.new(STDERR)
AppPerfRpm.logger.level = Logger::INFO
