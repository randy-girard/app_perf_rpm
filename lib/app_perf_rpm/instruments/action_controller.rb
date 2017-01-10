module AppPerfRpm
  module Instruments
    module ActionController
      def process_action_with_trace(method_name, *args)
        if ::AppPerfRpm::Tracer.tracing?
          opts = {
            :controller => self.class.name,
            :action => self.action_name
          }

          opts.merge!(::AppPerfRpm::Backtrace.backtrace_and_source_extract)

          AppPerfRpm::Tracer.trace('actioncontroller', opts) do
            process_action_without_trace(method_name, *args)
          end
        else
          process_action_without_trace(method_name, *args)
        end
      end

      def perform_action_with_trace(*arguments)
        if ::AppPerfRpm::Tracer.tracing?
          opts = {
            :controller  => @_request.path_parameters['controller'],
            :action      => @_request.path_parameters['action']
          }

          opts.merge!(::AppPerfRpm::Backtrace.backtrace_and_source_extract)

          AppPerfRpm::Tracer.trace('actioncontroller', opts) do
            perform_action_without_trace(*arguments)
          end
        else
          perform_action_without_trace(*arguments)
        end
      end
    end
  end
end

if defined?(::ActionController)
  AppPerfRpm.logger.info "Initializing actioncontroller tracer."

  ::ActionController::Base.send(
    :include,
    AppPerfRpm::Instruments::ActionController
  )

  ::ActionController::Base.class_eval do
    if ::Rails::VERSION::MAJOR > 2
      alias_method :process_action_without_trace, :process_action
      alias_method :process_action, :process_action_with_trace
    else
      alias_method :perform_action_without_trace, :perform_action
      alias_method :perform_action, :perform_action_with_trace
    end
  end
end
