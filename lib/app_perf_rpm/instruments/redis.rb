# frozen_string_literal: true

module AppPerf
  module Instruments
    module Redis
      include AppPerfRpm::Utils

      def call_with_trace(*command, &block)
        span = ::AppPerfRpm.tracer.start_span(tags: {
          "component" => "Redis",
          "db.address" => self.host,
          "db.port" => self.port,
          "db.type" => "redis",
          "db.vendor" => "redis",
          "db.instance" => self.db,
          "db.statement" => format_redis_command(*command)
        })
        span.log_source_and_backtrace(:redis)

        call_without_trace(*command, &block)
      rescue Exception => e
        if span
          span.set_tag('error', true)
          span.log_error(e)
        end
        raise
      ensure
        span.finish if span
      end

      def call_pipeline_with_trace(*pipeline)
        span = ::AppPerfRpm.tracer.start_span(tags: {
          "component" => "Redis",
          "db.address" => self.host,
          "db.port" => self.port,
          "db.type" => "redis",
          "db.vendor" => "redis",
          "db.instance" => self.db,
          "db.statement" => pipeline[0].commands.map { |c| format_redis_command(c) }.join("\n")
        })
        span.log_source_and_backtrace(:redis)

        call_pipeline_without_trace(*pipeline)
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

if ::AppPerfRpm.config.instrumentation[:redis][:enabled] &&
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
