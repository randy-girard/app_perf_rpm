module AppPerfRubyAgent
  module Instrument
  end
end

require 'app_perf_ruby_agent/instrument/base'
require 'app_perf_ruby_agent/instrument/action_controller'
require 'app_perf_ruby_agent/instrument/action_mailer'
require 'app_perf_ruby_agent/instrument/action_view'
require 'app_perf_ruby_agent/instrument/active_record'
require 'app_perf_ruby_agent/instrument/rack'
require 'app_perf_ruby_agent/instrument/garbage_collection'
require 'app_perf_ruby_agent/instrument/errors'
require 'app_perf_ruby_agent/instrument/sequel'
require 'app_perf_ruby_agent/instrument/sinatra'
require 'app_perf_ruby_agent/instrument/tilt'
require 'app_perf_ruby_agent/instrument/memory'
