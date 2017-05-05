require 'app_perf_rpm/monitors/base'
require 'sys-cpu'

module AppPerfRpm
  module Monitors
    class Cpu < Base
      def name
        "CPU"
      end

      def value
        Sys::CPU.load_avg[0]
      end

      def unit
        "%"
      end
    end
  end
end

AppPerfRpm.logger.info "Initializing cpu monitor."
