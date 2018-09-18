# frozen_string_literal: true

module AppPerfRpm
  module Instruments
    module Sinatra
      module Base
        def dispatch_with_trace
          span = ::AppPerfRpm.tracer.start_span(tags: {
            "component" => "Sinatra",
            "controller" => self.class.to_s,
            "action" => env["PATH_INFO"]
          })
          span.log_source_and_backtrace(:sinatra)

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
          span = ::AppPerfRpm.tracer.start_span(tags: {
            "component" => "Sinatra",
            "engine" => engine,
            "name" => data,
            "line_number" => __LINE__,
            "template" => __FILE__
          })
          span.log_source_and_backtrace(:sinatra)

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
