module AppPerfRubyAgent
  class Engine < ::Rails::Engine

    attr_accessor :collector, :smc

    config.apm = AppPerfRubyAgent::Config.new

    initializer "app_perf.initialize", :after => :load_config_initializers do |app|

      require 'app_perf_ruby_agent/probe'
      require 'app_perf_ruby_agent/instrument'

      self.smc = config.apm
      self.smc.load(app)
      raise ArgumentError.new(smc.errors) if smc.invalid?
      self.collector = AppPerfRubyAgent::Collector.new(smc.store)
      self.smc.collector = collector
    #end

    #initializer "app_perf.start_subscriber", :before => "app_perf.add_middleware" do |app|
      ActiveSupport::Notifications.subscribe /^[^!]/ do |*args|
        unless smc.notification_exclude_patterns.any? { |pattern| pattern =~ name }
          process_event AppPerfRubyAgent::NestedEvent.new(*args)
        end
      end
    #end

    #initializer "app_perf.add_middleware", :before => :load_environment_config do |app|
      Rails.application.config.middleware.use AppPerfRubyAgent::Middleware, collector, smc.path_exclude_patterns
    end

    private

    def process_event(event)
      instrument = smc.instruments.find { |instrument| instrument.handles?(event) }
      if instrument.present?
        unless instrument.ignore?(event)
          instrument.prepare(event)
          collector.collect_event(event)
        end
      else
        collector.collect_event(event)
      end
    end
  end
end
