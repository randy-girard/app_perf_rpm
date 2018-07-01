# frozen_string_literal: true

module AppPerfRpm
  module Instruments
    module Roda
      def call_with_trace(&block)
        if AppPerfRpm::Tracer.tracing?
          req = ::Rack::Request.new(env)
          request_method = req.request_method.to_s.upcase
          path = req.path

          parts = path.to_s.rpartition("/")
          action = parts.last
          controller = parts.first.sub(/\A\//, '').split("/").collect {|w| w.capitalize }.join("::")
          operation = "#{controller}##{action}"

          span = AppPerfRpm.tracer.start_span(operation, tags: {
            "component" => "Roda",
            "http.url" => path,
            "http.method" => request_method,
            "params" => @_request.params
          })
          AppPerfRpm::Utils.log_source_and_backtrace(span, :roda)
        end

        call_without_trace(&block)
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
end

if defined?(::Roda) && ::AppPerfRpm.config.instrumentation[:roda][:enabled]
  ::AppPerfRpm.logger.info "Initializing roda tracer."

  ::Roda::RodaPlugins::Base::InstanceMethods.send(:include, AppPerfRpm::Instruments::Roda)
  ::Roda::RodaPlugins::Base::InstanceMethods.class_eval do
    alias_method :call_without_trace, :call
    alias_method :call, :call_with_trace
  end
end
