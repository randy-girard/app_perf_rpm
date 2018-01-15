require "action_controller/railtie"
require 'active_support/all'
require 'action_controller'
require 'action_dispatch'
require 'rspec/rails'

module Rails
  class App
    def config; OpenStruct.new(:root => ""); end
    def env_config; {} end
    def env_defaults; @env_defaults ||= {}; end
    def routes
      return @routes if defined?(@routes)
      @routes = ActionDispatch::Routing::RouteSet.new
      @routes.draw do
        resources :tests # Replace with your own needs
      end
      @routes
    end
  end

  def self.application
    @app ||= App.new
  end
end

require 'support/apps/controllers'
