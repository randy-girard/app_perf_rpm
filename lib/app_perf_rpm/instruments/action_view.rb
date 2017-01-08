if defined?(::ActionView)
  if Rails::VERSION::MAJOR == 2
    ActionView::Partials.module_eval do
      alias :render_partial_without_trace :render_partial
      def render_partial(options = {})
        if ::AppPerfRpm.tracing? && options.key?(:partial) && options[:partial].is_a?(String)
          opts = {
            :method => :render_partial,
            :name => options[:partial],
            :file => __FILE__,
            :line_number => __LINE__
          }

          opts.merge!(:backtrace => ::AppPerfRpm::Backtrace.backtrace)
          opts.merge!(:source => ::AppPerfRpm::Backtrace.source_extract)

          AppPerfRpm::Tracer.trace("actionview", opts) do
            render_partial_without_trace(options)
          end
        else
          render_partial_without_trace(options)
        end
      end

      alias :render_partial_collection_without_trace :render_partial_collection
      def render_partial_collection(options = {})
        if ::AppPerfRpm.tracing?
          opts = {
            :method => :render_partial_collection,
            :name => @path,
            :file => __FILE__,
            :line_number => __LINE__
          }

          opts.merge!(:backtrace => ::AppPerfRpm::Backtrace.backtrace)
          opts.merge!(:source => ::AppPerfRpm::Backtrace.source_extract)

          AppPerfRpm::Tracer.trace("actionview", opts) do
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
        if ::AppPerfRpm.tracing?
          opts = {
            :method => :render_partial,
            :name => @options[:partial],
            :file => __FILE__,
            :line_number => __LINE__
          }

          opts.merge!(:backtrace => ::AppPerfRpm::Backtrace.backtrace)
          opts.merge!(:source => ::AppPerfRpm::Backtrace.source_extract)

          AppPerfRpm::Tracer.trace("actionview", opts) do
            render_partial_without_trace
          end
        else
          render_partial_without_trace
        end
      end

      alias :render_collection_without_trace :render_collection
      def render_collection
        if ::AppPerfRpm.tracing?
          opts = {
            :method => :render_collection,
            :name => @path,
            :file => __FILE__,
            :line_number => __LINE__
          }

          opts.merge!(:backtrace => ::AppPerfRpm::Backtrace.backtrace)
          opts.merge!(:source => ::AppPerfRpm::Backtrace.source_extract)

          AppPerfRpm::Tracer.trace("actionview", opts) do
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
        if ::AppPerfRpm.tracing?
          layout = nil

          opts = {
            :file => __FILE__,
            :line_number => __LINE__
          }
          opts.merge!(:backtrace => ::AppPerfRpm::Backtrace.backtrace)
          opts.merge!(:source => ::AppPerfRpm::Backtrace.source_extract)

          if path
            if method(:find_layout).arity == 3
              # Rails 5
              layout = find_layout(path, locals.keys, [formats.first])
            else
              # Rails 3, 4
              layout = find_layout(path, locals.keys)
            end

            opts[:path] = path
          end

          if layout
            opts[:method] = :render_with_layout
            opts[:name] = layout.identifier
            opts[:layout] = layout
            AppPerfRpm::Tracer.trace("actionview", opts) do
              render_with_layout_without_trace(path, locals, *args, &block)
            end
          else
            opts[:method] = :render_without_layout
            AppPerfRpm::Tracer.trace("actionview", opts) do
              render_with_layout_without_trace(path, locals, *args, &block)
            end
          end
        else
          render_with_layout_without_trace(path, locals, *args, &block)
        end
      end
    end
  end

  AppPerfRpm.logger.info "Initializing actionview tracer."
end
