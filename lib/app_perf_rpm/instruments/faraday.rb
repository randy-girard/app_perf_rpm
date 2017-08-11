module AppPerfRpm
  module Instruments
    module FaradayConnection
      def run_request_with_trace(method, url, body, headers, &block)
        if ::AppPerfRpm.tracing?
          span = ::AppPerfRpm::Tracer.start_span("faraday")
          result = run_request_without_trace(method, url, body, headers, &block)
          span.finish
          span.options = {
            "middleware" => @builder.handlers,
            "protocol" => @url_prefix.scheme,
            "remote_host" => @url_prefix.host,
            "remote_port" => @url_prefix.port,
            "service_url" => url,
            "http_method" => method,
            "http_status" => result.status
          }
          span.submit(opts)

          result
        else
          run_request_without_trace(method, url, body, headers, &block)
        end
      end
    end
  end
end

if ::AppPerfRpm.configuration.instrumentation[:faraday][:enabled] && defined?(::Faraday)
  ::AppPerfRpm.logger.info "Initializing faraday tracer."

  ::Faraday::Connection.send(:include, AppPerfRpm::Instruments::FaradayConnection)
  ::Faraday::Connection.class_eval do
    alias_method :run_request_without_trace, :run_request
    alias_method :run_request, :run_request_with_trace
  end
end
