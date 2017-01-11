require 'app_perf_rpm/monitors/base'

module AppPerfRpm
  module Monitors
    class Memory < Base
      def name
        "Memory"
      end

      def value
        `ps -o rss= -p #{Process.pid}`.to_i
      end

      def unit
        "kb"
      end

      def interval
        60
      end
    end
  end
end

AppPerfRpm.logger.info "Initializing memory monitor."
