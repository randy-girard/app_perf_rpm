# frozen_string_literal: true

if ::AppPerfRpm.config.instrumentation[:action_view][:enabled] && defined?(::ActionView) && defined?(Rails)
  require 'app_perf_rpm/instruments/action_view/action_view_rails_2'
  require 'app_perf_rpm/instruments/action_view/action_view_rails_3_0'
  require 'app_perf_rpm/instruments/action_view/action_view_rails_3_1_to_5'
  require 'app_perf_rpm/instruments/action_view/action_view_rails_6'
  
  AppPerfRpm.logger.info "Initializing actionview tracer."
end
