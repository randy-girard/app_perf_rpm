module AppPerfRubyAgent
  module Probe
    class Sinatra < AppPerfRubyAgent::Probe::Base

      def active?
        true
      end

      if defined?(::Sinatra)
        ::Sinatra::Base.class_eval do
          alias dispatch_without_trace! dispatch!
          alias compile_template_without_trace compile_template

          def dispatch!(*args, &block)
            ::ActiveSupport::Notifications.instrument(
              "process_action.sinatra",
              controller: self.class,
              action: env['PATH_INFO']
            ) do
              dispatch_without_trace!(*args, &block)
            end
          end

          def compile_template(engine, data, options, *args, &block)
            compile_template_without_trace(engine, data, options, *args, &block)
          end
        end
      end
    end
  end
end