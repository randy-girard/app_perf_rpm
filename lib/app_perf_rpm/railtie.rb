module AppPerfRpm
  class Railtie < ::Rails::Railtie
    require 'app_perf_rpm/instruments/rack'

    # TODO: Why this isn't working with the initializer?
    initializer "app_perf.initialize" do |app|
      unless AppPerfRpm.disable_agent?
        app.middleware.use AppPerfRpm::Middleware

        if ::AppPerfRpm.configuration.instrumentation[:rack][:enabled]
          AppPerfRpm.logger.info "Initializing rack tracer."
          app.middleware.insert 0, AppPerfRpm::Instruments::Rack

          if AppPerfRpm.configuration.instrumentation[:rack][:trace_middleware]
            AppPerfRpm.logger.info "Initializing rack middleware tracer."
            require 'app_perf_rpm/instruments/rack_middleware'
            app.middleware.insert 1, AppPerfRpm::Instruments::RackMiddleware
          end
        end
      end

      config.after_initialize do
        AppPerfRpm.configuration.app_root = Rails.root
        AppPerfRpm.configuration.reload
        AppPerfRpm.load
      end
    end
  end
end
