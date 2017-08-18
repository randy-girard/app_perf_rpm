module AppPerfRpm
  class Railtie < ::Rails::Railtie
    # TODO: Why this isn't working with the initializer?
    initializer "app_perf.initialize" do |app|
      unless AppPerfRpm.disable_agent?
        require 'app_perf_rpm/instruments/rack'
        app.middleware.use AppPerfRpm::Middleware
      end

      config.after_initialize do
        AppPerfRpm.configuration.app_root = Rails.root
        AppPerfRpm.configuration.reload
        AppPerfRpm.load
      end
    end
  end
end
