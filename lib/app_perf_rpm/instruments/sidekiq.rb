module AppPerfRpm
  class SidekiqServer
    def call(*args)
      worker, msg, queue = args
      opts = {
        :type => :job,
        :queue => queue,
        :job_name => worker.class.to_s,
        :controller => "Sidekiq_#{queue}",
        :action =>  msg['wrapped'],
        :url => "/sidekiq/#{queue}/#{msg['wrapped']}",
        :domain => Socket.gethostname
      }

      opts.merge!(:backtrace => ::AppPerfRpm.clean_trace)

      result = AppPerfRpm::Tracer.start_trace("sidekiq-worker", opts) do
        yield
      end

      result
    end
  end

  class SidekiqClient
    def call(*args)
      worker, msg, queue = args
      opts = {}

      opts.merge!(:backtrace => ::AppPerfRpm.clean_trace)

      result = AppPerfRpm::Tracer.trace("sidekiq-client", opts) do
        yield
      end

      result
    end
  end
end

if defined?(::Sidekiq)
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
