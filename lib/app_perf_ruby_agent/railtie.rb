module AppPerfRubyAgent
  class Railtie < Rails::Railtie
    agent = AppPerfRubyAgent::App.new
    initializer "app_perf.initialize", :after => :load_config_initializers do |app|
      agent.setup(app.root.to_s)
      agent.subscribe

      Rails.application.config.middleware.use AppPerfRubyAgent::Middleware, agent.collector, agent.smc.path_exclude_patterns
    end
  end
end
