if ::AppPerfRpm.configuration.instrumentation[:action_view][:enabled] && defined?(::ActionView)
  if defined?(Rails) && Rails::VERSION::MAJOR == 2
    ActionView::Partials.module_eval do
      alias :render_partial_without_trace :render_partial
      def render_partial(options = {})
        if ::AppPerfRpm::Tracer.tracing? && options.key?(:partial) && options[:partial].is_a?(String)
          opts = {
            "method" => "render_partial",
            "name" => options[:partial]
          }

          opts["backtrace"] = ::AppPerfRpm::Backtrace.backtrace
          opts["source"] = ::AppPerfRpm::Backtrace.source_extract

          AppPerfRpm::Tracer.trace("actionview", opts) do |span|
            span.controller = @_request.path_parameters['controller']
            span.action = @_request.path_parameters['action']
            span.backtrace = ::AppPerfRpm::Backtrace.backtrace
            span.source = ::AppPerfRpm::Backtrace.source_extract

            render_partial_without_trace(options)
          end
        else
          render_partial_without_trace(options)
        end
      end

      alias :render_partial_collection_without_trace :render_partial_collection
      def render_partial_collection(options = {})
        if ::AppPerfRpm::Tracer.tracing?
          AppPerfRpm::Tracer.trace("actionview") do |span|
            span.backtrace = ::AppPerfRpm::Backtrace.backtrace
            span.source = ::AppPerfRpm::Backtrace.source_extract
            span.options = {
              "method" => "render_partial_collection",
              "name" => @path
            }

            render_partial_collection_without_trace(options)
          end
        else
          render_partial_collection_without_trace(options)
        end
      end
    end
  else
    ActionView::PartialRenderer.class_eval do
      alias :render_partial_without_trace :render_partial
      def render_partial
        if ::AppPerfRpm::Tracer.tracing?
          AppPerfRpm::Tracer.trace("actionview") do |span|
            span.backtrace = ::AppPerfRpm::Backtrace.backtrace
            span.source = ::AppPerfRpm::Backtrace.source_extract
            span.options = {
              "method" => "render_partial",
              "name" => @options[:partial]
            }

            render_partial_without_trace
          end
        else
          render_partial_without_trace
        end
      end

      alias :render_collection_without_trace :render_collection
      def render_collection
        if ::AppPerfRpm::Tracer.tracing?
          AppPerfRpm::Tracer.trace("actionview") do |span|
            span.options = {
              "method" => "render_collection",
              "name" => @path
            }

            render_collection_without_trace
          end
        else
          render_collection_without_trace
        end
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

          AppPerfRpm::Tracer.trace("actionview") do |span|
            if layout
              span.options = {
                "method" => "render_with_layout",
                "name" => layout.identifier,
                "path" => @path,
                "layout" => layout
              }
            else
              span.options = {
                "method" => "render_without_layout",
                "path" => @path
              }
            end
            render_with_layout_without_trace(path, locals, *args, &block)
          end
        else
          render_with_layout_without_trace(path, locals, *args, &block)
        end
      end
    end
  end

  AppPerfRpm.logger.info "Initializing actionview tracer."
end
