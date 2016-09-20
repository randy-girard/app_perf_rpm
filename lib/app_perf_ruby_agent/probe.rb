module AppPerfRubyAgent
  module Probe
  end
end

require 'app_perf_ruby_agent/probes/base'
require 'app_perf_ruby_agent/probes/garbage_collection'
require 'app_perf_ruby_agent/probes/memory'
require 'app_perf_ruby_agent/probes/sequel'
require 'app_perf_ruby_agent/probes/sinatra'
require 'app_perf_ruby_agent/probes/tilt'
require 'app_perf_ruby_agent/probes/nginx'
