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
          @monitoring.log
          if @dispatcher.ready?
            @dispatcher.dispatch
            @dispatcher.reset
            @monitoring.reset
          end
          sleep (start + 5 - Time.now)
        end
      end
      @worker_thread.abort_on_exception = true
    end
  end
end
