require 'oj'

module AppPerfRpm
  require 'app_perf_rpm/logger'
  require 'app_perf_rpm/configuration'
  require 'app_perf_rpm/dispatcher'
  require 'app_perf_rpm/worker'
  require 'app_perf_rpm/backtrace'
  require 'app_perf_rpm/tracer'
  require 'app_perf_rpm/utils'
  require 'app_perf_rpm/middleware'
  require 'app_perf_rpm/instrumentation'
  require 'app_perf_rpm/monitoring'
  require 'app_perf_rpm/rails'
  require 'app_perf_rpm/introspector'

  class << self
    attr_writer :configuration

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def load
      #Oj.mimic_JSON
      unless disable_agent?
        AppPerfRpm::Instrumentation.load
        AppPerfRpm::Monitoring.load
        @worker = ::AppPerfRpm::Worker.new

        if @worker.start
          @worker_running = true
          AppPerfRpm.tracing_on
        end
      end
    end

    def worker
      @worker
    end

    def mutex
      @mutex ||= Mutex.new
    end

    def store(event)
      if @worker_running && tracing?
        @worker.save(event)
      end
      event
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
      @tracing
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
      if configuration.agent_disabled
        true
      elsif Introspector.agentable?
        false
      else
        true
      end
    end

  end
end
