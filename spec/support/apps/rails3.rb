require "rails/all"
require 'rspec/rails'
require "support/db_helper"

if Rails::VERSION::MAJOR == 3
  module Rails
    class Application
      class Configuration
        def database_configuration
          {
            'development' => {
              'adapter' => 'sqlite3',
              'database' => ':memory:',
            },
            'test' => {
              'adapter' => 'sqlite3',
              'database' => ':memory:',
            }
          }
        end
      end
    end
  end
end

class Rails3 < Rails::Application
  config.secret_token = 'f624861242e4ccf20eacb6bb48a886da'
  config.consider_all_requests_local = true
end

Rails3.initialize!

require 'support/apps/controllers'

if Rails.version >= "3.1"
  Rails.application.routes.draw do
    resources :tests, :only => [:index]
  end
else
  Rails::Application.routes.draw do
    resources :tests, :only => [:index]
  end
end

require 'support/apps/models'
