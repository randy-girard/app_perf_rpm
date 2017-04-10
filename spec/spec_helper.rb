require 'bundler/setup'
Bundler.setup

require 'simplecov'
SimpleCov.start

require 'app_perf_rpm'
AppPerfRpm.configuration.agent_disabled = true
AppPerfRpm.logger.level = Logger::WARN #enable when needed

RSpec.configure do |config|
  config.order = :random
end
