module AppPerfRpm
  module Instruments
    module RackModule
      def call(env)
        req = ::Rack::Request.new(env)
        status, headers, body = nil, nil, nil

        if ::AppPerfRpm::Tracer.in_trace? &&
          ::AppPerfRpm.configuration.instrumentation[:rack][:trace_middleware]
          AppPerfRpm::Tracer.trace("rack-middleware") do |span|
            span.type = "web"
            span.domain = req.host
            span.url = req.path
            span.options["class"] = @app.class.name

            status, headers, body = @app.call env
          end
        else
          AppPerfRpm::Tracer.start_trace("rack") do |span|
            span.type = "web"
            span.domain = req.host
            span.url = req.path
            span.options["class"] = @app.class.name

            status, headers, body = @app.call env
          end
        end

        [status, headers, body]
      end
    end
  end
end

if ::AppPerfRpm.configuration.instrumentation[:rack][:enabled]
  ::AppPerfRpm.logger.info "Initializing rack tracer."

  if ::AppPerfRpm.configuration.instrumentation[:rack][:trace_middleware]
    ::AppPerfRpm.logger.info "Initializing rack-middleware tracer."
  end

  module AppPerfRpm
    module Instruments
      class Rack
        include AppPerfRpm::Instruments::RackModule

        def initialize(app)
          @app = app
        end
      end
    end
  end

  module ActionDispatch
    class MiddlewareStack
      class AppPerfRack
        include AppPerfRpm::Instruments::RackModule

        def initialize(app)
          @app = app
        end
      end

      class Middleware
        def build(app)
          AppPerfRack.new(klass.new(app, *args, &block))
        end
      end

      def build(app = nil, &block)
        app ||= block
        raise "AppPerfRack#build requires an app" unless app
        middlewares.reverse.inject(AppPerfRack.new(app)) {|a, e| e.build(a)}
      end
    end
  end
end
