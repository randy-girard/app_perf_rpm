if defined?(Net::HTTP)
  ::AppPerfRpm.logger.info "Initializing net-http tracer."

  Net::HTTP.class_eval do
    def request_with_trace(*args, &block)
      opts = {}

      if args.length && args[0]
        req = args[0]

        opts[:protocol] = use_ssl? ? :https : :http
        opts[:path] = req.path
        opts[:method] = req.method
        opts[:remote_host] = addr_port
      end

      trace = ::AppPerfRpm::Tracer.start_instance("net-http")
      opts.merge!(:backtrace => ::AppPerfRpm.clean_trace)
      response = request_without_trace(*args, &block)
      trace.finish
      opts[:status] = response.code
      if ((300..308).to_a.include? response.code.to_i) && response.header["Location"]
        opts[:location] = response.header["Location"]
      end
      trace.submit(opts)
      response
    end

    alias request_without_trace request
    alias request request_with_trace
  end
end
