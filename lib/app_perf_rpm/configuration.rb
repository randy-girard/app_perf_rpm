# frozen_string_literal: true

require 'yaml'

module AppPerfRpm
  class Configuration
    attr_accessor :app_root,
                  :host,
                  :port,
                  :license_key,
                  :ssl,
                  :sample_rate,
                  :sample_threshold,
                  :flush_interval,
                  :application_name,
                  :instrumentation,
                  :agent_disabled,
                  :ignore_paths

    def initialize
      reload
    end

    def reload
      ::AppPerfRpm.mutex.synchronize do
        self.app_root = app_root ? Pathname.new(app_root.to_s) : nil
        self.host ||= default_if_blank(ENV["APP_PERF_HOST"], "http://localhost:5000")
        self.ssl ||= false
        self.license_key ||= default_if_blank(ENV["APP_PERF_LICENSE_KEY"], nil)
        self.application_name ||= "Default"
        self.sample_rate ||= 10 # Percentage of request to sample
        self.sample_threshold ||= 0 # Minimum amount of duration to sample
        self.flush_interval ||= 60 # In seconds
        self.agent_disabled ||= default_if_blank(ENV["APP_PERF_AGENT_DISABLED"], false)
        self.ignore_paths ||= /\/assets/
        self.instrumentation = {
          :rack                    => { :enabled => true, :backtrace => :app, :source => true, :trace_middleware => false },
          :roda                    => { :enabled => true, :backtrace => :app, :source => true },
          :grape                   => { :enabled => true, :backtrace => :app, :source => true },
          :active_record           => { :enabled => true, :backtrace => :app, :source => true },
          :active_record_import    => { :enabled => true, :backtrace => :app, :source => true },
          :active_model_serializer => { :enabled => true, :backtrace => :app, :source => true },
          :action_view             => { :enabled => true, :backtrace => :app, :source => true },
          :action_controller       => { :enabled => true, :backtrace => :app, :source => true },
          :emque_consuming         => { :enabled => true, :backtrace => :app, :source => true },
          :redis                   => { :enabled => true, :backtrace => :app, :source => true },
          :sequel                  => { :enabled => true, :backtrace => :app, :source => true },
          :sidekiq                 => { :enabled => true, :backtrace => :app, :source => true },
          :sinatra                 => { :enabled => true, :backtrace => :app, :source => true },
          :net_http                => { :enabled => true, :backtrace => :app, :source => true },
          :typhoeus                => { :enabled => true, :backtrace => :app, :source => true },
          :faraday                 => { :enabled => true, :backtrace => :app, :source => true }
        }
      end
    end

    private

    def default_if_blank(value, default)
      value.nil? || value.blank? ? default : value
    end
  end
end
