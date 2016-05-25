module AppPerfRubyAgent
  module Instrument
    class GarbageCollection < AppPerfRubyAgent::Instrument::Base

      def initialize
        super /^app\.gc$/
      end

      def active?
        true
      end

      def prepare(event)
        gc_time = GC::Profiler.total_time
        event.duration = gc_time * 1_000
      end

    end
  end
end
