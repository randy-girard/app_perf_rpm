module AppPerfRpm
  require 'app_perf_rpm/logger'
  require 'app_perf_rpm/configuration'
  require 'app_perf_rpm/dispatcher'
  require 'app_perf_rpm/worker'
  require 'app_perf_rpm/tracer'
  require 'app_perf_rpm/utils'
  require 'app_perf_rpm/middleware'
  require 'app_perf_rpm/instrumentation'
  require 'app_perf_rpm/rails'

  class << self
    attr_writer :configuration

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def load
      AppPerfRpm::Instrumentation.load
      @worker = ::AppPerfRpm::Worker.new

      if @worker.start
        @worker_running = true
        AppPerfRpm.tracing_on
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

    def log_event(event)
      @worker.log_event(event)
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

    def clean_trace(ignore = 0)
      bt = Kernel.caller
      bt.slice!(0, ignore)
      backtrace = trim_backtrace(bt)
      mark_as_app(backtrace)
    end

    def app_root
      if defined?(::Rails)
        if ::Rails::VERSION::MAJOR > 2
          Rails.root.to_s
        else
          RAILS_ROOT.to_s
        end
      else
        ""
      end
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
        return down.to_s
      else
        return up.to_s
      end
    end

    def mark_as_app(backtrace)
      backtrace.map {|bt|
        bt.to_s[/^#{app_root}\//] ?
          "*#{bt}" :
          bt
      }
    end

    def trim_backtrace(backtrace)
      return backtrace unless backtrace.is_a?(Array)

      length = backtrace.size
      if length > 100
        # Trim backtraces by getting the first 180 and last 20 lines
        trimmed = backtrace[0, 80] + ['...[snip]...'] + backtrace[length - 20, 20]
      else
        trimmed = backtrace
      end
      trimmed
    end
  end
end
