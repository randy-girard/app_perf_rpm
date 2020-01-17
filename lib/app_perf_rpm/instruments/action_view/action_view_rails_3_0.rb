if Rails::VERSION::MAJOR == 3 && Rails::VERSION::MINOR == 0
  ::ActionView::Partials::PartialRenderer.class_eval do
    alias :render_partial_without_trace :render_partial
    def render_partial
      if ::AppPerfRpm::Tracer.tracing?
        span = AppPerfRpm.tracer.start_span("render_partial", tags: {
          "component" => "ActionView",
          "span.kind" => "client",
          "view.template" => @options[:partial]
        })
        AppPerfRpm::Utils.log_source_and_backtrace(span, :action_view)
      end

      render_partial_without_trace
    rescue Exception => e
      if span
        span.set_tag('error', true)
        span.log_error(e)
      end
      raise
    ensure
      span.finish if span
    end

    alias :render_collection_without_trace :render_collection
    def render_collection
      if ::AppPerfRpm::Tracer.tracing?
        span = AppPerfRpm.tracer.start_span("render_collection", tags: {
          "component" => "ActionView",
          "span.kind" => "client",
          "view.template" => @path
        })
        if @_request
          span.set_tag('view.controller', @_request.path_parameters['controller'])
          span.set_tag('view.action', @_request.path_parameters['action'])
        end
        AppPerfRpm::Utils.log_source_and_backtrace(span, :action_view)
      end

      render_collection_without_trace
    rescue Exception => e
      if span
        span.set_tag('error', true)
        span.log_error(e)
      end
      raise
    ensure
      span.finish if span
    end
  end

  ::ActionView::Rendering.class_eval do
    alias :_render_template_without_trace _render_template

    def _render_template(template, layout = nil, options = {})
      if ::AppPerfRpm::Tracer.tracing?
        span = AppPerfRpm.tracer.start_span("render_template")
        span.set_tag "view.template", template
        span.set_tag "view.layout", layout
        span.set_tag "component", "ActionView"
        span.set_tag "span.kind", "client"
        AppPerfRpm::Utils.log_source_and_backtrace(span, :action_view)
      end

      _render_template_without_trace(template, layout, options)
    rescue Exception => e
      if span
        span.set_tag('error', true)
        span.log_error(e)
      end
      raise
    ensure
      span.finish if span
    end
  end
end
