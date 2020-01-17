if Rails.version >= '6.0.0'
  ActionView::PartialRenderer.class_eval do
    alias :render_partial_without_trace :render_partial
    def render_partial(context, template)
      if ::AppPerfRpm::Tracer.tracing?
        span = AppPerfRpm.tracer.start_span("render_partial", tags: {
          "component" => "ActionView",
          "span.kind" => "client",
          "view.template" => @options[:partial]
        })
        AppPerfRpm::Utils.log_source_and_backtrace(span, :action_view)
      end

      render_partial_without_trace(context, template)
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
    def render_collection(context, template)
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

      render_collection_without_trace(context, template)
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

  ::ActionView::TemplateRenderer.class_eval do
    alias :render_template_without_trace :render_template

    def render_template(view, template, layout_name = nil, locals = {})
      if ::AppPerfRpm::Tracer.tracing?
        layout = if layout_name
                   if layout_name.is_a?(String)
                     layout_name
                   elsif layout_name.is_a?(Proc)
                     layout_name.call
                   elsif method(:find_layout).arity == 3
                     find_layout(layout_name, locals, [formats.first])
                   elsif locals
                     find_layout(layout_name, locals)
                   end
                 end
        span = AppPerfRpm.tracer.start_span("render_template")
        span.set_tag "view.layout", layout ? layout.inspect : ""
        span.set_tag "view.template", template.inspect
        span.set_tag "component", "ActionView"
        span.set_tag "span.kind", "client"
        AppPerfRpm::Utils.log_source_and_backtrace(span, :action_view)
      end

      render_template_without_trace(view, template, layout_name, locals)
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
