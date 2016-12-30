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
          :domain => req.host,
          :url => req.path
        }

        if ignore_path?(req.path)
          @status, @headers, @response = @app.call(env)
        else
          opts.merge!(:backtrace => ::AppPerfRpm.clean_trace)
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
