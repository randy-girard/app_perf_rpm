require 'spec_helper'
require 'support/rails'

describe TestsController, :type => :controller do
  render_views if respond_to?(:render_views)

  it "should collect span" do
    AppPerfRpm::Instrumentation.load
    AppPerfRpm.tracing_on

    allow(AppPerfRpm::Tracer).to receive(:sampled?) { true }

    action_controller_span = double("Span")
    expect(action_controller_span).to receive(:log).with(event: "backtrace", stack: anything)
    expect(action_controller_span).to receive(:log).with(event: "source", stack: anything)
    expect(action_controller_span).to receive(:finish)
    expect(AppPerfRpm.tracer).to receive(:start_span).with("TestsController#index", tags: {
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
    expect(action_view_render_span).to receive(:set_tag).with("view.layout", /layouts\/application/)
    expect(action_view_render_span).to receive(:set_tag).with("view.template", anything)
    expect(action_view_render_span).to receive(:set_tag).with("component", "ActionView")
    expect(action_view_render_span).to receive(:set_tag).with("span.kind", "client")
    expect(action_view_render_span).to receive(:log).with(event: "backtrace", stack: anything)
    expect(action_view_render_span).to receive(:log).with(event: "source", stack: anything)
    expect(action_view_render_span).to receive(:finish)
    expect(AppPerfRpm::tracer).to receive(:start_span).with("render_template") { action_view_render_span }

    get :index

    expect(response).to be_ok

    AppPerfRpm.tracing_off
  end
end
