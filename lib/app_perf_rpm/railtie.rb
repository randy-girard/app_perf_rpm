module AppPerfRpm
  class Railtie < ::Rails::Railtie
    require 'app_perf_rpm/instruments/rack'

    # TODO: Why this isn't working with the initializer?
    initializer "app_perf.initialize" do |app|
      app.middleware.use AppPerfRpm::Middleware

      AppPerfRpm.logger.info "Initializing rack middleware tracer."
      app.middleware.insert 0, AppPerfRpm::Instruments::Rack
    end

    config.after_initialize do
      AppPerfRpm.configuration.app_root = Rails.root
      AppPerfRpm.load
    end
  end
end
