require 'support/db_helper'
require "rails/all"
require 'rspec/rails'

module AppPerfRpm
  class TestRailsApp < Rails::Application
    # common settings between all Rails versions
    def initialize(*args)
      super(*args)

      config.secret_key_base = 'f624861242e4ccf20eacb6bb48a886da'
      config.secret_token = 'f624861242e4ccf20eacb6bb48a886da'
      config.eager_load = false
      config.consider_all_requests_local = true
    end

    def do_initialization!
      if Rails.application.respond_to?(:secrets)
        Rails.application.secrets[:secret_key_base] = 'f624861242e4ccf20eacb6bb48a886da'
        Rails.application.secrets[:secret_token] = 'f624861242e4ccf20eacb6bb48a886da'
      elsif Rails.application.respond_to?(:config)
        Rails.application.config.secret_key_base = 'f624861242e4ccf20eacb6bb48a886da'
        Rails.application.config.secret_token = 'f624861242e4ccf20eacb6bb48a886da'
      end

      require 'support/apps/controllers'
      initialize!
      require 'support/apps/models'
    end
  end
end
