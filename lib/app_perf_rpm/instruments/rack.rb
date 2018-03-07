# frozen_string_literal: true

module AppPerfRpm
  module Instruments
    module RackModule
      def call(env)
        req = ::Rack::Request.new(env)

        #if ::AppPerfRpm::Tracer.in_trace? &&
        #  ::AppPerfRpm.config.instrumentation[:rack][:trace_middleware]
        #  AppPerfRpm::Tracer.trace("rack-middleware") do |span|
        #    span.set_tag "type", "web"
        #    span.set_tag "domain", req.host
        #    span.set_tag "url", req.path
        #    span.set_tag "class", @app.class.name
        #
        #    status, headers, body = @app.call env
        #  end
        #else
        span = AppPerfRpm.tracer.start_span("rack")
        span.set_tag "type", "web"
        span.set_tag "domain", req.host
        span.set_tag "url", req.path
        span.set_tag "class", @app.class.name
        span.set_tag "backtrace", ::AppPerfRpm::Backtrace.backtrace
        span.set_tag "source", ::AppPerfRpm::Backtrace.source_extract

        @app.call(env)
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

if ::AppPerfRpm.config.instrumentation[:rack][:enabled]
  ::AppPerfRpm.logger.info "Initializing rack tracer."

  if ::AppPerfRpm.config.instrumentation[:rack][:trace_middleware]
    ::AppPerfRpm.logger.info "Initializing rack-middleware tracer."
  end

  module AppPerfRpm
    module Instruments
      class Rack
        attr_reader :app

        #include AppPerfRpm::Instruments::RackModule

        def initialize(app)
          @app = app
        end

        def call(env)
          req = ::Rack::Request.new(env)

          unless ignore_path?(req.path)
            extracted_ctx = AppPerfRpm.tracer.extract(OpenTracing::FORMAT_RACK, env)
            AppPerfRpm::Tracer.sample!(extracted_ctx, !!req.params["app-perf-sample"])

            if AppPerfRpm::Tracer.tracing?
              span = AppPerfRpm.tracer.start_span(@app.class.name, :child_of => extracted_ctx, tags: {
                "component" => "Rack",
                "span.kind" => "client"
              })
              AppPerfRpm::Utils.log_source_and_backtrace(span, :rack)
            end
          end

          status, headers, response = @app.call(env)

          if span
            span.set_tag "peer.address", req.host
            span.set_tag "peer.port", req.port
            span.set_tag "http.method", req.request_method
            span.set_tag "http.url", req.path
            span.set_tag "http.status_code", status
          end

          [status, headers, response]
        rescue Exception => e
          if span
            span.set_tag('error', true)
            span.log_error(e)
          end
          raise
        ensure
          span.finish if span
          AppPerfRpm::Tracer.sample_off!
        end

        def ignore_path?(path)
          path.to_s =~ AppPerfRpm.config.ignore_paths
        end
      end
    end
  end
=begin
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
=end
end
