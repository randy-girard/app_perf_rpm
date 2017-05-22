module AppPerfRpm
  class Worker
    def initialize
      AppPerfRpm.logger.info "Starting worker."
      @dispatcher = Dispatcher.new
      @monitoring = Monitoring.new
    end

    def save(event)
      start
      return if event.nil?
      @dispatcher.add_event(event)
    end

    def start
      return if worker_running?
      ::AppPerfRpm.mutex.synchronize do
        return if worker_running?
        start_dispatcher
        ::AppPerfRpm.logger.info "Worker is running."
      end
    end

    def worker_running?
      @worker_thread && @worker_thread.alive?
    end

    def start_dispatcher
      @worker_thread = Thread.new do
        ::AppPerfRpm.configuration.reload
        @dispatcher.reset

        loop do
          start = Time.now
          @monitoring.record
          if @dispatcher.ready? || @monitoring.ready?
            @monitoring.queue_for_dispatching
            @dispatcher.dispatch
            @dispatcher.reset
            @monitoring.reset
          end
          sleep_for = (start + 15 - Time.now)
          sleep_for = 1 if sleep_for < 1
          sleep sleep_for
        end
      end
      @worker_thread.abort_on_exception = true
    end
  end
end
