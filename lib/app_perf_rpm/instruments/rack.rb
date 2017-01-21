module AppPerfRpm
  module Instruments
    class Rack
      attr_reader :app

      def initialize(app)
        @app = app
      end

      def call(env)
        req = ::Rack::Request.new(env)

        opts = {
          "domain" => req.host,
          "url" => req.path
        }

        incoming_trace = env["HTTP_X_APP_PERF_TRACE"]
        incoming_trace_id = env["HTTP_X_APP_PERF_TRACE_ID"]

        if incoming_trace.to_s.eql?("1")
          opts.merge!("trace_id" => incoming_trace_id)
        end

        if ignore_path?(req.path)
          @status, @headers, @response = @app.call(env)
        else
          opts["backtrace"] = ::AppPerfRpm::Backtrace.backtrace
          opts["source"] = ::AppPerfRpm::Backtrace.source_extract
          AppPerfRpm::Tracer.start_trace("rack", opts) do
            @status, @headers, @response = @app.call(env)
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
