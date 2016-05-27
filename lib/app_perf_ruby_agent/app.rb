module AppPerfRubyAgent
  class App
    attr_accessor :collector, :smc

    def setup(app)
      require 'app_perf_ruby_agent/probe'
      require 'app_perf_ruby_agent/instrument'

      self.smc = AppPerfRubyAgent.config
      self.smc.load(app)
      raise ArgumentError.new(smc.errors) if smc.invalid?
      self.collector = AppPerfRubyAgent::Collector.new(smc.store)
      self.smc.collector = collector
    end

    def subscribe
      ActiveSupport::Notifications.subscribe /^[^!]/ do |*args|
        unless smc.notification_exclude_patterns.any? { |pattern| pattern =~ name }
          process_event AppPerfRubyAgent::NestedEvent.new(*args)
        end
      end
    end

    private

    def process_event(event)
      instrument = AppPerfRubyAgent.config.instruments.find { |instrument| instrument.handles?(event) }
      if instrument
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