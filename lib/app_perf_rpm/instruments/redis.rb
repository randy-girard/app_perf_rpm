module AppPerf
  module Instruments
    module Redis
      def call_with_trace(command, &block)
        if ::AppPerfRpm::Tracer.tracing?
          ::AppPerfRpm::Tracer.trace("redis") do |span|
            call_without_trace(command, &block)
          end
        else
          call_without_trace(command, &block)
        end
      end

      def call_pipeline_with_trace(pipeline)
        if ::AppPerfRpm::Tracer.tracing?
          ::AppPerfRpm::Tracer.trace("redis") do |span|
            call_pipeline_without_trace(pipeline)
          end
        else
          call_pipeline_without_trace(pipeline)
        end
      end
    end
  end
end

if ::AppPerfRpm.configuration.instrumentation[:redis][:enabled] &&
  defined?(::Redis)
  ::AppPerfRpm.logger.info "Initializing redis tracer."

  ::Redis::Client.send(:include, ::AppPerf::Instruments::Redis)

  ::Redis::Client.class_eval do
    alias_method :call_without_trace, :call
    alias_method :call, :call_with_trace
    alias_method :call_pipeline_without_trace, :call_pipeline
    alias_method :call_pipeline, :call_pipeline_with_trace
  end
end
