# frozen_string_literal: true

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
  end

  if defined?(Rails) && Rails::VERSION::MAJOR == 3 && Rails::VERSION::MINOR == 0
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

  if defined?(Rails) && Rails.version >= '3.1.0'
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

    ::ActionView::TemplateRenderer.class_eval do
      alias :render_template_without_trace :render_template

      def render_template(template, layout_name = nil, locals = {})
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

        render_template_without_trace(template, layout_name, locals)
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
