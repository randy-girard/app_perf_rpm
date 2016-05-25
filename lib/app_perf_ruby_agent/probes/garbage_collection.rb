module AppPerfRubyAgent
  module Probe
    class GarbageCollection < AppPerfRubyAgent::Probe::Base
      def active?
        true
      end

      def on_start
        GC::Profiler.clear
      end

      def on_finish
        instrument
      end

      def instrument
        ::ActiveSupport::Notifications.instrument("app.gc")
      end
    end
  end
end
