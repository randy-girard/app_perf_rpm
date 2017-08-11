module AppPerfRpm
  module Instruments
    module Sinatra
      module Base
        def dispatch_with_trace
          if ::AppPerfRpm::Tracer.tracing?
            ::AppPerfRpm::Tracer.trace("sinatra") do |span|
              span.controller = self.class.to_s
              span.action = env["PATH_INFO"]

              dispatch_without_trace
            end
          else
            dispatch_without_trace
          end
        end

        def handle_exception_with_trace(boom)
          handle_exception_without_trace(boom)
        end
      end

      module Templates
        def render_with_trace(engine, data, options = {}, locals = {}, &block)
          if ::AppPerfRpm::Tracer.tracing?
            name = data

            ::AppPerfRpm::Tracer.trace("sinatra") do |span|
              span.options = {
                "engine" => engine,
                "name" => name,
                "type" => "render",
                "file" => __FILE__,
                "line_number" => __LINE__
              }

              render_without_trace(engine, data, options, locals, &block)
            end
          else
            render_without_trace(engine, data, options, locals, &block)
          end
        end
      end
    end
  end
end

if ::AppPerfRpm.configuration.instrumentation[:sinatra][:enabled] &&
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
