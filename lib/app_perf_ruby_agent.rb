require 'socket'

module AppPerfRubyAgent
  def self.host
    @host ||= Socket.gethostname
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

require 'app_perf_ruby_agent/instrument'
require 'app_perf_ruby_agent/instrument/base'
require 'app_perf_ruby_agent/instrument/action_controller'
require 'app_perf_ruby_agent/instrument/action_mailer'
require 'app_perf_ruby_agent/instrument/action_view'
require 'app_perf_ruby_agent/instrument/active_record'
require 'app_perf_ruby_agent/instrument/rack'
require 'app_perf_ruby_agent/instrument/ruby_vm'
require 'app_perf_ruby_agent/instrument/errors'

require 'app_perf_ruby_agent/monitor'
require 'app_perf_ruby_agent/monitor/base'
require 'app_perf_ruby_agent/monitor/memory'

require 'app_perf_ruby_agent/engine'