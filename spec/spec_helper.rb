require 'bundler/setup'
Bundler.setup

require 'simplecov'
SimpleCov.start

require 'app_perf_rpm'
AppPerfRpm.config.agent_disabled = true
AppPerfRpm.config.application_name = "AppPerfRpm"
AppPerfRpm.config.app_root = Pathname.new(File.expand_path("../../", __FILE__))
AppPerfRpm.config.sample_rate = 100
AppPerfRpm.logger.level = Logger::WARN #enable when needed

RSpec.configure do |config|
  config.order = :random
end
