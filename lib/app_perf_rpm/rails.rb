if defined?(::Rails)
  if ::Rails::VERSION::MAJOR > 2
    require 'app_perf_rpm/railtie'
  else
    Rails.configuration.after_initialize do
      AppPerfRpm.load
      Rails.configuration.middleware.use AppPerfRpm::Middleware
      AppPerfRpm.logger.info "Initializing rack middleware tracer."
      Rails.configuration.middleware.insert 0, AppPerfRpm::Instruments::Rack
    end
  end
end
