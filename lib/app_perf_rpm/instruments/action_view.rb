# frozen_string_literal: true

if ::AppPerfRpm.config.instrumentation[:action_view][:enabled] && defined?(::ActionView)
  if defined?(Rails) && Rails::VERSION::MAJOR == 2
    ActionView::Partials.module_eval do
      alias :render_partial_without_trace :render_partial
      def render_partial(options = {})
        if options.key?(:partial) && options[:partial].is_a?(String)
          span = AppPerfRpm.tracer.start_span(tags: {
            "component" => "ActionView",
            "context" => "partial",
            "controller" => @_request.path_parameters['controller'],
            "action" => @_request.path_parameters['action'],
            "template" => options[:partial]
          })
          span.log_source_and_backtrace(:action_view)
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
        span = AppPerfRpm.tracer.start_span(tags: {
          "component" => "ActionView",
          "context" => "partial",
          "controller" => @_request.path_parameters['controller'],
          "action" => @_request.path_parameters['action'],
          "template" => @path
        })
        span.log_source_and_backtrace(:action_view)

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
        span = AppPerfRpm.tracer.start_span(tags: {
          "component" => "ActionView",
          "context" => "partial",
          "template" => @options[:partial]
        })
        span.log_source_and_backtrace(:action_view)

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
        span = AppPerfRpm.tracer.start_span(tags: {
          "component" => "ActionView",
          "context" => "collection",
          "template" => @path
        })
        if @_request
          span.set_tag('controller', @_request.path_parameters['controller'])
          span.set_tag('action', @_request.path_parameters['action'])
        end
        span.log_source_and_backtrace(:action_view)

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
        span = AppPerfRpm.tracer.start_span
        span.set_tag "template", template
        span.set_tag "layout", layout
        span.set_tag "component", "ActionView"
        span.set_tag "context", "template"
        span.log_source_and_backtrace(:action_view)

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
        span = AppPerfRpm.tracer.start_span(tags: {
          "component" => "ActionView",
          "context" => "partial",
          "template" => @options[:partial]
        })
        span.log_source_and_backtrace(:action_view)

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
          span = AppPerfRpm.tracer.start_span(tags: {
            "component" => "ActionView",
            "context" => "collection",
            "template" => @path
          })
          if @_request
            span.set_tag('controller', @_request.path_parameters['controller'])
            span.set_tag('action', @_request.path_parameters['action'])
          end
          span.log_source_and_backtrace(:action_view)
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
          layout = if layout_name.is_a?(String)
                     layout_name
                   elsif layout_name.is_a?(Proc)
                     layout_name.call
                   elsif method(:find_layout).arity == 3
                     find_layout(layout_name, locals, [formats.first])
                   elsif locals
                     find_layout(layout_name, locals)
                   end
          span = AppPerfRpm.tracer.start_span
          span.set_tag "layout", layout ? layout.inspect : ""
          span.set_tag "template", template.inspect
          span.set_tag "component", "ActionView"
          span.set_tag "context", "template"
          span.log_source_and_backtrace(:action_view)
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
