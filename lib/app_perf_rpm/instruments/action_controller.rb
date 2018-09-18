# frozen_string_literal: true

module AppPerfRpm
  module Instruments
    module ActionController
      def process_action_with_trace(method_name, *args)
        span = AppPerfRpm.tracer.start_span(tags: {
          "controller" => self.class.name,
          "action" => self.action_name,
          "component" => "ActionController"
        })
        span.log_source_and_backtrace(:action_controller)

        process_action_without_trace(method_name, *args)
      rescue Exception => e
        puts e.message.inspect
        puts e.backtrace.join("\n")
        if span
          span.set_tag('error', true)
          span.log_error(e)
        end
        raise
      ensure
        span.finish if span
      end

      def perform_action_with_trace(*arguments)
        span = AppPerfRpm.tracer.start_span(tags: {
          "controller" => @_request.path_parameters['controller'],
          "action" => @_request.path_parameters['action'],
          "component" => "ActionController"
        })
        span.log_source_and_backtrace(:action_controller)

        perform_action_without_trace(*arguments)
      rescue Exception => e
        if span
          span.set_tag('error', true)
          span.log_error(e)
        end
        raise
      ensure
        span.finish if span
      end
    end
  end
end

if ::AppPerfRpm.config.instrumentation[:action_controller][:enabled] &&
  defined?(::ActionController)
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
