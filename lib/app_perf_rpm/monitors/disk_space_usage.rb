require 'app_perf_rpm/monitors/base'
require 'sys-filesystem'

module AppPerfRpm
  module Monitors
    class DiskSpaceUsage < Base
      def name
        "Disk Space Usage (%)"
      end

      def value
         Sys::Filesystem.stat("/").percent_used
      end

      def unit
        "%"
      end
    end
  end
end

AppPerfRpm.logger.info "Initializing disk space usage monitor."
