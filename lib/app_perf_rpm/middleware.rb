module AppPerfRpm
  class Middleware
    attr_reader :app

    def initialize(app)
      @app = app
    end

    def call(env)
      begin
        @response = @app.call(env)
      rescue Exception => e
        handle_exception(env, e)
      end
      @response
    end

    def handle_exception(env, exception)
      ::AppPerfRpm::Tracer.log_event("error",
        :path => env["PATH_INFO"],
        :method => env["REQUEST_METHOD"],
        :message => exception.message,
        :error_class => exception.class.to_s,
        :backtrace => ::AppPerfRpm::Backtrace.clean(exception.backtrace),
        :source => ::AppPerfRpm::Backtrace.source_extract(exception.backtrace)
      )
      raise exception
    end
  end
end
