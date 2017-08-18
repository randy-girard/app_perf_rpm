if defined?(::Rails)
  if ::Rails::VERSION::MAJOR > 2
    require 'app_perf_rpm/railtie'
  else
    Rails.configuration.after_initialize do
      unless AppPerfRpm.disable_agent?
        AppPerfRpm.load
        Rails.configuration.middleware.use AppPerfRpm::Middleware
      end
    end
  end
end
