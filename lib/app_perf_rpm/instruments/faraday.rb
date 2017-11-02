module AppPerfRpm
  module Instruments
    module FaradayConnection
      def run_request_with_trace(method, url, body, headers, &block)
        if ::AppPerfRpm.tracing?
          span = ::AppPerfRpm.tracer.start_span("faraday", tags: {
            "component" => "Faraday",
            "span.kind" => "client"
          })
          result = run_request_without_trace(method, url, body, headers, &block)
          span.set_tag "middleware", @builder.handlers
          span.set_tag "peer.hostname", @url_prefix.host
          span.set_tag "peer.port", @url_prefix.port
          span.set_tag "http.protocol", @url_prefix.scheme
          span.set_tag "http.url", url
          span.set_tag "http.method", method
          span.set_tag "http.status_code", result.status
          span.log(event: "backtrace", stack: ::AppPerfRpm::Backtrace.backtrace)
          span.log(event: "source", stack: ::AppPerfRpm::Backtrace.source_extract)
          span.finish
        else
          run_request_without_trace(method, url, body, headers, &block)
        end
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
