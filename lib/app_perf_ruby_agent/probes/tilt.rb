module AppPerfRubyAgent
  module Probe
    class Tilt < AppPerfRubyAgent::Probe::Base

      def active?
        true
      end

      if defined?(::Tilt)
        ::Tilt::Template.class_eval do
          alias render_without_trace render

          def render(*args, &block)
            ::ActiveSupport::Notifications.instrument(
              "render.tilt",
              args: args
            ) do
              render_without_trace(*args, &block)
            end
          end
        end
      end
    end
  end
end