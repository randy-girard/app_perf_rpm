# frozen_string_literal: true

module AppPerfRpm
  class Railtie < ::Rails::Railtie
    initializer "app_perf.initialize" do |app|
      unless AppPerfRpm.disable_agent?
        require 'app_perf_rpm/instruments/rack'
        AppPerfRpm.logger.info "Initializing rack middleware tracer."
        app.middleware.insert 0, AppPerfRpm::Instruments::Rack
      end

      config.after_initialize do
        AppPerfRpm.config.app_root = Rails.root
        AppPerfRpm.config.reload
        AppPerfRpm.load
      end
    end
  end
end
