if ::AppPerfRpm.configuration.instrumentation[:net_http][:enabled] && defined?(Net::HTTP)
  ::AppPerfRpm.logger.info "Initializing net-http tracer."

  Net::HTTP.class_eval do
    def request_with_trace(*args, &block)
      if ::AppPerfRpm::Tracer.tracing?
        opts = {}

        if args.length && args[0]
          req = args[0]

          opts["protocol"] = use_ssl? ? "https" : "http"
          opts["path"] = req.path
          opts["method"] = req.method
          opts["remote_host"] = addr_port
        end

        opts["backtrace"] = ::AppPerfRpm::Backtrace.backtrace
        opts["source"] = ::AppPerfRpm::Backtrace.source_extract
        trace = ::AppPerfRpm::Tracer.start_instance("net-http")
        response = request_without_trace(*args, &block)
        trace.finish
        opts[:status] = response.code
        if (response.code.to_i >= 300 || response.code.to_i <= 308) && response.header["Location"]
          opts["location"] = response.header["Location"]
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
