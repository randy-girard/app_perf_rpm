# frozen_string_literal: true

if ::AppPerfRpm.config.instrumentation[:net_http][:enabled] && defined?(Net::HTTP)
  ::AppPerfRpm.logger.info "Initializing net-http tracer."

  Net::HTTP.class_eval do
    def request_with_trace(*args, &block)
      if ::AppPerfRpm::Tracer.tracing?
        span = ::AppPerfRpm.tracer.start_span("net-http", tags: {
          "component" => "NetHttp",
          "span.kind" => "client"
        })

        if args.length && args[0]
          req = args[0]
          AppPerfRpm.tracer.inject(span.context, OpenTracing::FORMAT_RACK, req)
          span.set_tag "http.protocol", (use_ssl? ? "https" : "http")
          span.set_tag "http.url", req.path
          span.set_tag "http.method", req.method
          span.set_tag "peer.hostname", addr_port
          AppPerfRpm::Utils.log_source_and_backtrace(span, :net_http)
        end

        response = request_without_trace(*args, &block)

        span.exit
        span.set_tag "http.status_code", response.code

        if (response.code.to_i >= 300 || response.code.to_i <= 308) && response.header["Location"]
          span.set_tag "http.redirect", response.header["Location"]
        end

        span.finish
      else
        response = request_without_trace(*args, &block)
      end
      response
    end

    alias request_without_trace request
    alias request request_with_trace
  end
end
