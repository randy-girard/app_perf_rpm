require 'yaml'

module AppPerfRubyAgent
  class Config
    attr_accessor :store, :instruments, :probes, :notification_exclude_patterns, :path_exclude_patterns, :options, :root, :host, :port, :ssl, :license_key, :sample_threshold, :collector

    def initialize

    end

    def load(root)
      self.root = root.to_s
      yaml = YAML.load_file(root + "/app_perf_ruby_agent.yml")

      self.host = yaml["host"]
      self.port = yaml["port"]
      self.ssl = yaml["ssl"]
      self.license_key = yaml["license_key"]
      self.sample_threshold = yaml["sample_threshold"] || 2000

      self.store = AppPerfRubyAgent::Store.new
      self.notification_exclude_patterns = []
      self.path_exclude_patterns = []

      self.instruments = [
        AppPerfRubyAgent::Instrument::ActionController.new,
        AppPerfRubyAgent::Instrument::ActionView.new,
        AppPerfRubyAgent::Instrument::ActiveRecord.new,
        AppPerfRubyAgent::Instrument::Rack.new,
        AppPerfRubyAgent::Instrument::GarbageCollection.new,
        AppPerfRubyAgent::Instrument::Errors.new,
        AppPerfRubyAgent::Instrument::Sequel.new,
        AppPerfRubyAgent::Instrument::Sinatra.new,
        AppPerfRubyAgent::Instrument::Tilt.new,
        AppPerfRubyAgent::Instrument::Memory.new
      ]

      self.probes = [
        AppPerfRubyAgent::Probe::Memory.new,
        AppPerfRubyAgent::Probe::GarbageCollection.new,
        AppPerfRubyAgent::Probe::Sequel.new,
        AppPerfRubyAgent::Probe::Sinatra.new,
        AppPerfRubyAgent::Probe::Tilt.new
      ]
    end

    def valid?
      !invalid?
    end

    def invalid?
      store.nil? ||
        instruments.nil? ||
        notification_exclude_patterns.nil? ||
        path_exclude_patterns.nil?
    end

    def errors
      return nil if valid?
      errors = []
      errors << 'store cannot be nil' if store.nil?
      errors << 'instruments cannot be nil' if instruments.nil?
      errors << 'notification_exclude_patterns cannot be nil' if notification_exclude_patterns.nil?
      errors << 'path_exclude_patterns cannot be nil' if path_exclude_patterns.nil?
      errors.join("\n")
    end
  end
end
