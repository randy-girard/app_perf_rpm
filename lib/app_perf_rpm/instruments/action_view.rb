if defined?(::ActionView)
  if Rails::VERSION::MAJOR == 2
    ActionView::Partials.module_eval do
      alias :render_partial_without_trace :render_partial
      def render_partial(options = {})
        if options.key?(:partial) && options[:partial].is_a?(String)
          opts = {
            :type => :render_partial,
            :name => options[:partial],
            :file => __FILE__,
            :line_number => __LINE__
          }

          opts.merge!(:backtrace => ::AppPerfRpm.clean_trace)

          AppPerfRpm::Tracer.trace("actionview", opts) do
            render_partial_without_trace(options)
          end
        else
          render_partial_without_trace(options)
        end
      end

      alias :render_partial_collection_without_trace :render_partial_collection
      def render_partial_collection(options = {})
        opts = {
          :type => :render_partial_collection,
          :name => @path,
          :file => __FILE__,
          :line_number => __LINE__
        }

        opts.merge!(:backtrace => ::AppPerfRpm.clean_trace)

        AppPerfRpm::Tracer.trace("actionview", opts) do
          render_partial_collection_without_trace(options)
        end
      end
    end
  else
    ::ActionView::TemplateRenderer.class_eval do
      alias render_with_layout_without_trace render_with_layout

      def render_with_layout(path, locals, *args, &block) #:nodoc:
        layout = nil

        if path
          if method(:find_layout).arity == 3
            # Rails 5
            layout = find_layout(path, locals.keys, [formats.first])
          else
            # Rails 3, 4
            layout = find_layout(path, locals.keys)
          end
        end

        if layout
          opts = {
            :type => :render,
            :name => layout.identifier,
            :file => __FILE__,
            :line_number => __LINE__,
            :path => path,
            :layout => layout
          }

          opts.merge!(:backtrace => ::AppPerfRpm.clean_trace)

          AppPerfRpm::Tracer.trace("actionview", opts) do
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
