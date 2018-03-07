# frozen_string_literal: true

module AppPerfRpm
  module Instruments
    module FaradayConnection
      def run_request_with_trace(method, url, body, headers, &block)
        if ::AppPerfRpm::Tracer.tracing?
          span = ::AppPerfRpm.tracer.start_span("faraday", tags: {
            "component" => "Faraday",
            "span.kind" => "client"
          })
          AppPerfRpm.tracer.inject(span.context, OpenTracing::FORMAT_RACK, @headers)
          result = run_request_without_trace(method, url, body, headers, &block)
          span.set_tag "middleware", @builder.handlers
          span.set_tag "peer.hostname", @url_prefix.host
          span.set_tag "peer.port", @url_prefix.port
          span.set_tag "http.protocol", @url_prefix.scheme
          span.set_tag "http.url", url
          span.set_tag "http.method", method
          span.set_tag "http.status_code", result.status
          AppPerfRpm::Utils.log_source_and_backtrace(span, :faraday)
          span.finish
        else
          result = run_request_without_trace(method, url, body, headers, &block)
        end
        result
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

if ::AppPerfRpm.config.instrumentation[:faraday][:enabled] && defined?(::Faraday)
  ::AppPerfRpm.logger.info "Initializing faraday tracer."

  ::Faraday::Connection.send(:include, AppPerfRpm::Instruments::FaradayConnection)
  ::Faraday::Connection.class_eval do
    alias_method :run_request_without_trace, :run_request
    alias_method :run_request, :run_request_with_trace
  end
end
