module AppPerfRubyAgent
  module Probe
    class Memory < AppPerfRubyAgent::Probe::Base
      def active?
        true
      end

      def on_loop
        if ready?
          collect do
            instrument
          end
          reset
        end
      end

      def instrument
        ::ActiveSupport::Notifications.instrument(
          "app.memory",
          :value => `ps -o rss= -p #{Process.pid}`.to_i
        )
      end
    end
  end
end
