module AppPerfRubyAgent
  module Probe
    class Base
      def initialize
        reset
      end

      def active?
        false
      end

      def on_loop
      end

      def on_start
      end

      def on_finish
      end

      def collect
        AppPerfRubyAgent.config.collector.collect do
          yield
        end
      end

      def interval
        60
      end

      def ready?
        Time.now > @timer + interval
      end

      def reset
        @timer = Time.now
      end

      def instrument(options = {})
      end
    end
  end
end
