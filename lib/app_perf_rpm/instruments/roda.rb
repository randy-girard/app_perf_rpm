# frozen_string_literal: true

module AppPerf
  module Instruments
    module Roda
      def call_with_trace(&block)
        req = ::Rack::Request.new(env)
        request_method = req.request_method.to_s.upcase
        path = req.path

        parts = path.to_s.rpartition("/")
        action = parts.last
        controller = parts.first.sub(/\A\//, '').split("/").collect {|w| w.capitalize }.join("::")

        span = AppPerfRpm.tracer.start_span(tags: {
          "controller" => controller,
          "action" => action,
          "component" => "Roda",
          "url" => path,
          "method" => request_method,
          "params" => @_request.params
        })
        span.log_source_and_backtrace(:roda)

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

  ::Roda::RodaPlugins::Base::InstanceMethods.send(:include, AppPerf::Instruments::Roda)
  ::Roda::RodaPlugins::Base::InstanceMethods.class_eval do
    alias_method :call_without_trace, :call
    alias_method :call, :call_with_trace
  end
end
