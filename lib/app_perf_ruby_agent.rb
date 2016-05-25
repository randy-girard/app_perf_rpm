require 'socket'

module AppPerfRubyAgent
  def self.host
    @host ||= Socket.gethostname
  end

  def self.probes
    Rails.application.config.apm.probes.select(&:active?)
  end

  def self.round_time(t, sec = 1)
    down = t - (t.to_i % sec)
    up = down + sec

    difference_down = t - down
    difference_up = up - t

    if (difference_down < difference_up)
      return down.to_s
    else
      return up.to_s
    end
  end

  def self.clean_trace
    Rails.backtrace_cleaner.clean(caller[2..-1])
  end

  def self.collection_on
    Thread.current[:system_metrics_collecting] = true
  end

  def self.collection_off
    Thread.current[:system_metrics_collecting] = false
  end

  def collecting?
    Thread.current[:system_metrics_collecting] || false
  end

  def without_collection
    previously_collecting = collecting?
    AppPerfRubyAgent.collection_off
    yield if block_given?
  ensure
    AppPerfRubyAgent.collection_on if previously_collecting
  end

  module_function :collecting?, :without_collection
end

require 'app_perf_ruby_agent/version'
require 'app_perf_ruby_agent/nested_event'
require 'app_perf_ruby_agent/store'
require 'app_perf_ruby_agent/config'
require 'app_perf_ruby_agent/collector'
require 'app_perf_ruby_agent/middleware'
require 'app_perf_ruby_agent/engine'