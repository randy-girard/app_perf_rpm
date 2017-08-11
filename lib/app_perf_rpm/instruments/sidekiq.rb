module AppPerfRpm
  class SidekiqServer
    def call(*args)
      worker, msg, queue = args

      result = AppPerfRpm::Tracer.start_trace("sidekiq-worker") do |span|
        span.type = "job"
        span.controller = "Sidekiq_#{queue}"
        span.action = msg["wrapped"]
        span.url = "/sidekiq/#{queue}/#{msg['wrapped']}"
        span.domain = Socket.gethostname
        span.options = {
          "job_name" => worker.class.to_s,
          "queue" => queue
        }

        yield
      end

      result
    end
  end

  class SidekiqClient
    def call(*args)
      if ::AppPerfRpm::Tracer.tracing?
        worker, msg, queue = args

        result = AppPerfRpm::Tracer.trace("sidekiq-client") do |span|
          yield
        end
      else
        result = yield
      end
      result
    end
  end
end

if ::AppPerfRpm.configuration.instrumentation[:sidekiq][:enabled] &&
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
