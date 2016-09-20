module AppPerfRubyAgent
  module Probe
    class Nginx < AppPerfRubyAgent::Probe::Base
      def active?
        true
      end

      def on_start
        instrument
      end

      def instrument(options = {})
        env = options[:env]
        if env["HTTP_X_TRACE_ID"]
          ::ActiveSupport::Notifications.instrument(
            "web.nginx",
            :path => env["PATH_INFO"],
            :method => env["REQUEST_METHOD"],
            :trace_id => env["HTTP_X_TRACE_ID"],
            :trace_start => env["HTTP_X_TRACE_START"]
          )
        end
      end
    end
  end
end
