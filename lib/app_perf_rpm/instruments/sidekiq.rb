# frozen_string_literal: true

module AppPerfRpm
  class SidekiqServer
    def call(*args)
      worker, msg, queue = args

      parent_span_context = extract(msg)
      AppPerfRpm::Tracer.sample!(parent_span_context)

      if AppPerfRpm::Tracer.tracing?
        operation = "Sidekiq_#{queue}##{msg["wrapped"]}"
        span = AppPerfRpm.tracer.start_span(operation, :child_of => parent_span_context, tags: {
          "component" => "Sidekiq",
          "span.kind" => "server",
          "http.url" => "/sidekiq/#{queue}/#{msg['wrapped']}",
          "peer.address" => Socket.gethostname,
          "bg.queue" => queue,
          "bg.job_name" => worker.class.to_s
        })
        AppPerfRpm::Utils.log_source_and_backtrace(span, :sidekiq)
      end

      yield
    rescue Exception => e
      if span
        span.set_tag('error', true)
        span.log_error(e)
      end
      raise
    ensure
      span.finish if span
      AppPerfRpm::Tracer.sample_off!
    end

    private

    def extract(job)
      carrier = job[AppPerfRpm::TRACE_CONTEXT_KEY]
      return unless carrier
      AppPerfRpm::tracer.extract(OpenTracing::FORMAT_TEXT_MAP, carrier)
    end
  end

  class SidekiqClient
    def call(*args)
      worker, msg, queue = args

      if ::AppPerfRpm::Tracer.tracing?
        operation = "Sidekiq_#{queue}##{msg["wrapped"]}"
        span = AppPerfRpm.tracer.start_span(operation, tags: {
          "component" => "Sidekiq",
          "span.kind" => "client",
          "http.url" => "/sidekiq/#{queue}/#{msg['wrapped']}",
          "peer.address" => Socket.gethostname,
          "bg.queue" => queue,
          "bg.job_name" => worker.class.to_s
        })
        AppPerfRpm::Utils.log_source_and_backtrace(span, :sidekiq)

        inject(span, msg)
      end

      yield
    rescue Exception => e
      if span
        span.set_tag('error', true)
        span.log_error(e)
      end
      raise
    ensure
      span.finish if span
    end

    private

    def inject(span, job)
      carrier = {}
      AppPerfRpm.tracer.inject(span.context, OpenTracing::FORMAT_TEXT_MAP, carrier)
      job[AppPerfRpm::TRACE_CONTEXT_KEY] = carrier
    end
  end
end

if ::AppPerfRpm.config.instrumentation[:sidekiq][:enabled] &&
  defined?(::Sidekiq)
  AppPerfRpm.logger.info "Initializing sidekiq tracer."

  ::Sidekiq.configure_server do |config|
    config.server_middleware do |chain|
      chain.add ::AppPerfRpm::SidekiqServer
    end
  end

  ::Sidekiq.configure_client do |config|
    config.client_middleware do |chain|
      chain.add ::AppPerfRpm::SidekiqClient
    end
  end
end
