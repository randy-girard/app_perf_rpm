module AppPerfRpm
  module Instruments
    class RackMiddleware
      attr_reader :app

      def initialize(app)
        @app = app
        self.extend(AppPerfRpmRack)
      end

      def call(env)
        @app.call(env)
      end

      module AppPerfRpmRack
        def self.extended(object)
          object.singleton_class.class_eval do
            alias_method :call_without_tracing, :call
            alias_method :call, :call_with_tracing
            public :call
          end

          object.instance_eval do
            recursive_app_perf
          end
        end

        private

        def recursive_app_perf
          return if @app.nil?
          return unless @app.respond_to?(:call)
          @app.extend(AppPerfRpmRack)
        end

        def call_with_tracing(env)
          req = ::Rack::Request.new(env)

          incoming_trace = env["HTTP_X_APP_PERF_TRACE"]
          incoming_trace_id = env["HTTP_X_APP_PERF_TRACE_ID"]

          opts = {}
          if incoming_trace.to_s.eql?("1")
            opts.merge!("trace_id" => incoming_trace_id)
          end

          if !::AppPerfRpm::Tracer.tracing? || ignore_path?(req.path)
            @status, @headers, @response = @app.call_without_tracing(env)
          else
            AppPerfRpm::Tracer.trace("rack-middleware", opts) do |span|
              span.type = "web"
              span.domain = req.host
              span.url = req.path
              span.options["class"] = self.class.name

              @status, @headers, @response = @app.call_without_tracing(env)
            end
          end

          [@status, @headers, @response]
        end

        def ignore_path?(path)
          path.to_s =~ /\/assets/
        end
      end
    end
  end
end
