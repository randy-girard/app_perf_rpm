# frozen_string_literal: true

module AppPerfRpm
  module Instruments
    module Sinatra
      module Base
        def dispatch_with_trace
          if ::AppPerfRpm::Tracer.tracing?
            operation = "#{self.class}##{env["PATH_INFO"]}"
            span = ::AppPerfRpm.tracer.start_span(operation, tags: {
              component: "Sinatra"
            })
            AppPerfRpm::Utils.log_source_and_backtrace(span, :sinatra)
          end

          dispatch_without_trace
        rescue Exception => e
          if span
            span.set_tag('error', true)
            span.log_error(e)
          end
          raise
        ensure
          span.finish if span
        end

        def handle_exception_with_trace(boom)
          handle_exception_without_trace(boom)
        end
      end

      module Templates
        def render_with_trace(engine, data, options = {}, locals = {}, &block)
          if ::AppPerfRpm::Tracer.tracing?
            name = data

            span = ::AppPerfRpm.tracer.start_span("render", tags: {
              "component" => "Sinatra",
              "view.engine" => engine,
              "view.name" => name,
              "view.line_number" => __LINE__,
              "view.template" => __FILE__
            })
            AppPerfRpm::Utils.log_source_and_backtrace(span, :sinatra)
          end

          render_without_trace(engine, data, options, locals, &block)
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
end

if ::AppPerfRpm.config.instrumentation[:sinatra][:enabled] &&
  defined?(::Sinatra)
  ::AppPerfRpm.logger.info "Initializing sinatra tracer."

  ::Sinatra::Base.use AppPerfRpm::Instruments::Rack

  unless defined?(::Padrino)
    ::Sinatra::Base.send(:include, ::AppPerfRpm::Instruments::Sinatra::Base)
    ::Sinatra::Base.class_eval do
      alias_method :dispatch_without_trace, :dispatch!
      alias_method :dispatch!, :dispatch_with_trace
      alias_method :handle_exception_without_trace, :handle_exception!
      alias_method :handle_exception!, :handle_exception_with_trace
    end

    ::Sinatra::Templates.send(:include, ::AppPerfRpm::Instruments::Sinatra::Templates)
    ::Sinatra::Base.class_eval do
      alias_method :render_without_trace, :render
    end
  end
end
