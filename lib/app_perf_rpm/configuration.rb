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
          :rack                    => { :enabled => true, :backtrace => false, :source => false, :trace_middleware => false },
          :roda                    => { :enabled => true, :backtrace => false, :source => false },
          :grape                   => { :enabled => true, :backtrace => false, :source => false },
          :active_record           => { :enabled => true, :backtrace => false, :source => false },
          :active_record_import    => { :enabled => true, :backtrace => false, :source => false },
          :active_model_serializer => { :enabled => true, :backtrace => false, :source => false },
          :action_view             => { :enabled => true, :backtrace => false, :source => false },
          :action_controller       => { :enabled => true, :backtrace => false, :source => false },
          :emque_consuming         => { :enabled => true, :backtrace => false, :source => false },
          :redis                   => { :enabled => true, :backtrace => false, :source => false },
          :sequel                  => { :enabled => true, :backtrace => false, :source => false },
          :sidekiq                 => { :enabled => true, :backtrace => false, :source => false },
          :sinatra                 => { :enabled => true, :backtrace => false, :source => false },
          :net_http                => { :enabled => true, :backtrace => false, :source => false },
          :typhoeus                => { :enabled => true, :backtrace => false, :source => false },
          :faraday                 => { :enabled => true, :backtrace => false, :source => false }
        }
      end
    end

    private

    def default_if_blank(value, default)
      value.nil? || value.blank? ? default : value
    end
  end
end
