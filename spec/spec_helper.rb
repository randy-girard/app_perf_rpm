require 'bundler/setup'
Bundler.setup

require 'simplecov'
SimpleCov.start

require 'app_perf_rpm'
#AppPerfRpm.logger.level = Logger::DEBUG #enable when needed

RSpec.configure do |config|
  config.order = :random
end
