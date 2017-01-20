module AppPerfRpm
  module Instruments
    module TyphoeusRequest
      def run_with_trace
        if ::AppPerfRpm.tracing?
          instance = ::AppPerfRpm::Tracer.start_instance("typhoeus")
          response = run_without_trace
          instance.finish

          uri = URI(response.effective_url)

          opts = {}
          opts[:backtrace] = ::AppPerfRpm::Backtrace.backtrace
          opts[:source] = ::AppPerfRpm::Backtrace.source_extract
          opts[:http_status] = response.code
          opts[:remote_url] = uri.to_s
          opts[:http_method] = options[:method]
          instance.submit(opts)
          response
        else
          run_without_trace
        end
      end
    end

    module TyphoeusHydra
      def run_with_trace
        opts = {}
        opts[:method] = :hydra
        opts[:queued_requests] = queued_requests.count
        opts[:max_concurrency] = max_concurrency
        ::AppPerfRpm::Tracer.trace(:typhoeus, opts) do
          run_without_trace
        end
      end
    end
  end
end

if ::AppPerfRpm.configuration.instrumentation[:typhoeus][:enabled] && defined?(::Typhoeus)
  ::AppPerfRpm.logger.info "Initializing typhoeus tracer."

  ::Typhoeus::Request::Operations.send(:include, AppPerfRpm::Instruments::TyphoeusRequest)
  ::Typhoeus::Request::Operations.class_eval do
    alias_method :run_without_trace, :run
    alias_method :run, :run_with_trace
  end

  ::Typhoeus::Hydra.send(:include, AppPerfRpm::Instruments::TyphoeusHydra)
  ::Typhoeus::Hydra.class_eval do
    alias_method :run_without_trace, :run
    alias_method :run, :run_with_trace
  end
end
