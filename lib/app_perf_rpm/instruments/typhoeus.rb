module AppPerfRpm
  module Instruments
    module TyphoeusRequest
      def run_with_trace
        if ::AppPerfRpm.tracing?
          span = ::AppPerfRpm::Tracer.start_span("typhoeus")
          response = run_without_trace
          span.finish

          uri = URI(response.effective_url)

          span.options = {
            "http_status" => response.code,
            "remote_url" => uri.to_s,
            "http_method" => options[:method]
          }
          span.submit(opts)

          response
        else
          run_without_trace
        end
      end
    end

    module TyphoeusHydra
      def run_with_trace
        ::AppPerfRpm::Tracer.trace("typhoeus") do |span|
          span.options = {
            "method" => :hydra,
            "queued_requests" => queued_requests.count,
            "max_concurrency" => max_concurrency
          }
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
