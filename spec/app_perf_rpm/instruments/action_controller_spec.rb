require 'spec_helper'
require "action_controller/railtie"
require 'active_support/all'
require 'action_controller'
require 'action_dispatch'
require 'rspec/rails'

module Rails
  class App
    def config; OpenStruct.new(:root => ""); end
    def env_config; {} end
    def routes
      return @routes if defined?(@routes)
      @routes = ActionDispatch::Routing::RouteSet.new
      @routes.draw do
        resources :test # Replace with your own needs
      end
      @routes
    end
  end

  def self.application
    @app ||= App.new
  end
end

class TestController < ActionController::Base
  include Rails.application.routes.url_helpers
  prepend_view_path File.join("spec", "views")

  def index
  end
end

describe TestController, :type => :controller do
  render_views

  it "should collect span" do
    AppPerfRpm::Instrumentation.load
    AppPerfRpm.tracing_on

    allow(AppPerfRpm::Tracer).to receive(:sampled?) { true }

    action_controller_span = double("Span")
    expect(action_controller_span).to receive(:log).with(event: "backtrace", stack: anything)
    expect(action_controller_span).to receive(:log).with(event: "source", stack: anything)
    expect(action_controller_span).to receive(:finish)
    expect(AppPerfRpm.tracer).to receive(:start_span).with("TestController#index", tags: {
      "component" => "ActionController",
      "span.kind" => "client"
    }) { action_controller_span }

    action_view_partial_span = double("Span")
    expect(action_view_partial_span).to receive(:log).with(event: "backtrace", stack: anything)
    expect(action_view_partial_span).to receive(:log).with(event: "source", stack: anything)
    expect(action_view_partial_span).to receive(:finish)
    expect(AppPerfRpm::tracer).to receive(:start_span).with("render_partial", tags: {
      "component"=>"ActionView",
      "span.kind"=>"client",
      "view.template"=>"partial"
    }) { action_view_partial_span }

    action_view_render_span = double("Span")
    expect(action_view_render_span).to receive(:set_tag).with("component", "ActionView")
    expect(action_view_render_span).to receive(:set_tag).with("span.kind", "client")
    expect(action_view_render_span).to receive(:set_tag).with("view.template", nil)
    expect(action_view_render_span).to receive(:log).with(event: "backtrace", stack: anything)
    expect(action_view_render_span).to receive(:log).with(event: "source", stack: anything)
    expect(action_view_render_span).to receive(:finish)
    expect(AppPerfRpm::tracer).to receive(:start_span).with("render_without_layout") { action_view_render_span }

    get :index

    AppPerfRpm.tracing_off
  end
end
