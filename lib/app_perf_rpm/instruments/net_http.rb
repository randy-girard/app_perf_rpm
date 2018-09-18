# frozen_string_literal: true

if ::AppPerfRpm.config.instrumentation[:net_http][:enabled] && defined?(Net::HTTP)
  ::AppPerfRpm.logger.info "Initializing net-http tracer."

  Net::HTTP.class_eval do
    def request_with_trace(*args, &block)
      span = ::AppPerfRpm.tracer.start_span(tags: {
        "component" => "NetHttp"
      })

      if args.length && args[0]
        req = args[0]
        AppPerfRpm.tracer.inject(span.context, OpenTracing::FORMAT_RACK, req)
        span.set_tag "protocol", (use_ssl? ? "https" : "http")
        span.set_tag "url", req.path
        span.set_tag "method", req.method
        span.set_tag "hostname", addr_port
        span.log_source_and_backtrace(:net_http)
      end

      response = request_without_trace(*args, &block)

      span.exit
      span.set_tag "status_code", response.code

      if (response.code.to_i >= 300 || response.code.to_i <= 308) && response.header["Location"]
        span.set_tag "redirect", response.header["Location"]
      end

      span.finish

      response
    end

    alias request_without_trace request
    alias request request_with_trace
  end
end
