# frozen_string_literal: true

module AppPerfRpm
  require "opentracing"
  require 'msgpack'
  
  require 'app_perf_rpm/logger'
  require 'app_perf_rpm/configuration'
  require 'app_perf_rpm/backtrace'

  require 'app_perf_rpm/reporters/json_client'
  require 'app_perf_rpm/reporters/null_client'

  require 'app_perf_rpm/tracing/buffer'
  require 'app_perf_rpm/tracing/carrier'
  require 'app_perf_rpm/tracing/collector'
  require 'app_perf_rpm/tracing/endpoint'
  require 'app_perf_rpm/tracing/trace_id'
  require 'app_perf_rpm/tracing/span_context'
  require 'app_perf_rpm/tracing/span'
  require 'app_perf_rpm/tracing/managed_span'
  require 'app_perf_rpm/tracing/tracer'
  require 'app_perf_rpm/tracing/managed_tracer'
  require 'app_perf_rpm/tracing/thread_span_stack'

  require 'app_perf_rpm/tracer'
  require 'app_perf_rpm/utils'
  require 'app_perf_rpm/instrumentation'
  require 'app_perf_rpm/rails'
  require 'app_perf_rpm/introspector'

  TRACE_CONTEXT_KEY = 'AppPerf-Trace-Context'

  class << self

    attr_writer :config

    def config
      @config ||= Configuration.new
    end

    def configure
      yield(config)
    end

    def load
      #Oj.mimic_JSON
      unless disable_agent?
        AppPerfRpm::Instrumentation.load
        AppPerfRpm.tracing_on
      end
    end

    def mutex
      @mutex ||= Mutex.new
    end

    def endpoint
      @endpoint ||= AppPerfRpm::Tracing::Endpoint.local_endpoint(config.application_name)
    end

    def collector
      @collector ||= AppPerfRpm::Tracing::Collector.new(endpoint)
    end

    def url
      @url ||= "#{config.host}/api/listener/3/#{config.license_key}"
    end

    def sender
      @sender ||= AppPerfRpm::Reporters::JsonClient.new(
        url: url,
        collector: collector,
        flush_interval: config.flush_interval
      )
    end

    def tracer
      @tracer ||= AppPerfRpm::Tracing::ManagedTracer.new(
        AppPerfRpm::Tracing::Tracer.build(
          :service_name => config.application_name,
          :sender => sender,
          :collector => collector
        ),
        AppPerfRpm::Tracing::ThreadSpanStack.new
      )
    end

    def tracing_on
      if @without_tracing_enabled
        AppPerfRpm.logger.debug "Not turning tracing on due to without tracing mode."
        return
      end
      mutex.synchronize do
        AppPerfRpm.logger.debug "Enabling tracing."
        @tracing = true
      end
    end

    def tracing_off
      mutex.synchronize do
        AppPerfRpm.logger.debug "Disabling tracing."
        @tracing = false
      end
    end

    def tracing?
      !!@tracing
    end

    def without_tracing
      @previously_tracing = AppPerfRpm.tracing?
      @without_tracing_enabled = true
      AppPerfRpm.tracing_off
      yield if block_given?
      @without_tracing_enabled = false
    ensure
      AppPerfRpm.tracing_on if @previously_tracing
    end

    def host
      @host ||= Socket.gethostname
    end

    def round_time(t, sec = 1)
      t = Time.parse(t.to_s)

      down = t - (t.to_i % sec)
      up = down + sec

      difference_down = t - down
      difference_up = up - t

      if (difference_down < difference_up)
        return down
      else
        return up
      end
    end

    def floor_time(t, sec = 1)
      Time.at((t.to_f / sec).floor * sec)
    end

    def disable_agent?
      if config.agent_disabled
        true
      elsif Introspector.agentable?
        false
      else
        true
      end
    end

    def now
      if defined?(Process::CLOCK_REALTIME)
        Process.clock_gettime(Process::CLOCK_REALTIME)
      else
        Time.now
      end
    end

  end
end
