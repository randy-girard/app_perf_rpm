if ::AppPerfRpm.config.instrumentation[:action_view][:enabled] && defined?(::ActionView)
  if defined?(Rails) && Rails::VERSION::MAJOR == 2
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
  else
    ActionView::PartialRenderer.class_eval do
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
            "view.controller" => @_request.path_parameters['controller'],
            "view.action" => @_request.path_parameters['action'],
            "view.template" => @path
          })
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

    ::ActionView::TemplateRenderer.class_eval do
      alias render_with_layout_without_trace render_with_layout

      def render_with_layout(path, locals, *args, &block)
        if ::AppPerfRpm::Tracer.tracing?
          layout = nil

          if path
            if method(:find_layout).arity == 3
              # Rails 5
              layout = find_layout(path, locals.keys, [formats.first])
            else
              # Rails 3, 4
              layout = find_layout(path, locals.keys)
            end

            @path = path
          end

          if layout
            span = AppPerfRpm.tracer.start_span("render_with_layout")
            # span.set_tag "view.layout", layout
            span.set_tag "view.template", layout.identifier
          else
            span = AppPerfRpm.tracer.start_span("render_without_layout")
            if @path
              span.set_tag "view.template", @path.call
            end
          end
          span.set_tag "component", "ActionView"
          span.set_tag "span.kind", "client"
          AppPerfRpm::Utils.log_source_and_backtrace(span, :action_view)
        end

        render_with_layout_without_trace(path, locals, *args, &block)
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

  AppPerfRpm.logger.info "Initializing actionview tracer."
end
