if Rails::VERSION::MAJOR == 2
  ActionView::Partials.module_eval do
    alias :render_partial_without_trace :render_partial
    def render_partial(options = {})
      if ::AppPerfRpm::Tracer.tracing? && options.key?(:partial) && options[:partial].is_a?(String)
        span = AppPerfRpm.tracer.start_span("render_partial", tags: {
          "component" => "ActionView",
          "span.kind" => "client",
          "view.controller" => @_request.path_parameters['controller'],
          "view.action" => @_request.path_parameters['action'],
          "view.template" => options[:partial]
        })
        AppPerfRpm::Utils.log_source_and_backtrace(span, :action_view)
      end

      render_partial_without_trace(options)
    rescue Exception => e
      if span
        span.set_tag('error', true)
        span.log_error(e)
      end
      raise
    ensure
      span.finish if span
    end

    alias :render_partial_collection_without_trace :render_partial_collection
    def render_partial_collection(options = {})
      if ::AppPerfRpm::Tracer.tracing?
        span = AppPerfRpm.tracer.start_span("render_partial_collection", tags: {
          "component" => "ActionView",
          "span.kind" => "client",
          "view.controller" => @_request.path_parameters['controller'],
          "view.action" => @_request.path_parameters['action'],
          "view.template" => @path
        })
        AppPerfRpm::Utils.log_source_and_backtrace(span, :action_view)
      end

      render_partial_collection_without_trace(options)
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
