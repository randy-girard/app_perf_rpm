module AppPerfRubyAgent
  class Middleware
    def initialize(app, collector, path_exclude_patterns)
      @app = app
      @collector = collector
      @path_exclude_patterns = path_exclude_patterns
    end

    def call(env)
      if exclude_path? env["PATH_INFO"]
        @app.call(env)
      else
        @collector.collect do
          begin
            response = instrument(env) do
              @app.call(env)
            end
          rescue Exception => e
            handle_exception(env, e)
          end
          response
        end
      end
    end

    protected

    def instrument(env)
      AppPerfRubyAgent.web_server_probes.each {|p| p.instrument(:env => env) }
      notifications.instrument "request.rack", :path => env["PATH_INFO"], :method => env["REQUEST_METHOD"], :trace_id => env["HTTP_X_TRACE_ID"], :trace_start => env["HTTP_X_TRACE_START"] do
        AppPerfRubyAgent.probes.each(&:on_start)
        result = yield
        AppPerfRubyAgent.probes.each(&:on_start)
        result
      end
    end

    def handle_exception(env, exception)
      notifications.instrument "app.error", :path => env["PATH_INFO"], :method => env["REQUEST_METHOD"], :message => exception.message, :error_class => exception.class.to_s, :backtrace => exception.backtrace
      raise exception
    end

    def exclude_path?(path)
      @path_exclude_patterns.any? { |pattern| pattern =~ path }
    end

    def notifications
      ActiveSupport::Notifications
    end
  end
end
