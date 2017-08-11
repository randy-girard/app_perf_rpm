if ::AppPerfRpm.configuration.instrumentation[:net_http][:enabled] && defined?(Net::HTTP)
  ::AppPerfRpm.logger.info "Initializing net-http tracer."

  Net::HTTP.class_eval do
    def request_with_trace(*args, &block)
      if ::AppPerfRpm::Tracer.tracing?
        span = ::AppPerfRpm::Tracer.start_span("net-http")

        if args.length && args[0]
          req = args[0]
          span.options["protocol"] = use_ssl? ? "https" : "http"
          span.options["path"] = req.path
          span.options["method"] = req.method
          span.options["remote_host"] = addr_port
        end

        response = request_without_trace(*args, &block)

        span.finish
        span.options["status"] = response.code

        if (response.code.to_i >= 300 || response.code.to_i <= 308) && response.header["Location"]
          span.options["location"] = response.header["Location"]
        end

        trace.submit(opts)
      else
        response = request_without_trace(*args, &block)
      end
      response
    end

    alias request_without_trace request
    alias request request_with_trace
  end
end
