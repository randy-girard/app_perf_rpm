module AppPerfRpm
  class Worker
    def initialize
      AppPerfRpm.logger.info "Starting worker."

      @queue = Queue.new
      @event_queue = Queue.new
      @worker_mutex = Mutex.new
    end

    def save(event)
      start
      return if event.nil?
      @queue << event
    end

    def log_event(event)
      start
      return if event.nil?
      @event_queue << event
    end

    def mutex
      @worker_mutex
    end

    def start
      return if worker_running?
      @worker_mutex.synchronize do
        return if worker_running?
        initialize_dispatcher
        ::AppPerfRpm.logger.info "Worker is running."
      end
    end

    def reset
      @queue.clear
      @event_queue.clear
      @start_time = Time.now
    end

    def ready?
      Time.now > @start_time + 60
    end

    def worker_running?
      @worker_thread && @worker_thread.alive?
    end

    def initialize_dispatcher
      @worker_thread = Thread.new do
        reset

        loop do
          if ready?
            begin
              queue = drain_queue
              dispatch_events(queue.dup)
              event_queue = drain_event_queue
              dispatch_events(event_queue.dup)
            rescue => ex
              ::AppPerfRpm.logger.error "#{ex.inspect}"
              ::AppPerfRpm.logger.error "#{ex.backtrace.inspect}"
            ensure
              reset
            end
          end
          sleep 5
        end
      end
      @worker_thread.abort_on_exception = true
    end

    def drain_queue
      Array.new(@queue.size) { @queue.pop }
    end

    def drain_event_queue
      Array.new(@event_queue.size) { @event_queue.pop }
    end

    def url
      ssl = ::AppPerfRpm.configuration.ssl ? "https" : "http"
      host = ::AppPerfRpm.configuration.host
      port = ::AppPerfRpm.configuration.port
      license_key = ::AppPerfRpm.configuration.license_key
      @url ||= "#{ssl}://#{host}:#{port}/api/listener/2/#{license_key}"
    end

    def dispatch_events(data)
      if data && data.length > 0
        uri = URI(url)
        req = Net::HTTP::Post.new(uri.path, { "Content-Type" => "application/json", "Accept-Encoding" => "gzip", "User-Agent" => "gzip" })
        req.body = {
          "name" => ::AppPerfRpm.configuration.application_name,
          "host" => ::AppPerfRpm.configuration.host,
          "data" => data
        }.to_json
        res = Net::HTTP.start(uri.hostname, uri.port) do |http|
          http.read_timeout = 5
          http.request(req)
        end
        data.clear
      end
    end
  end
end
