require 'oj'

module AppPerfRpm
  class Dispatcher
    def initialize
      @start_time = Time.now
      @queue = Queue.new
    end

    def add_event(event)
      @queue << event
    end

    def configuration
      ::AppPerfRpm.configuration
    end

    def ready?
      Time.now > @start_time + configuration.dispatch_interval.to_f &&
      @queue.size.to_i > 0
    end

    def reset
      @queue.clear
      @start_time = Time.now
    end

    def dispatch
      begin
        events = drain(@queue)
        dispatch_events(events.dup)
      rescue => ex
        ::AppPerfRpm.logger.error "#{ex.inspect}"
        ::AppPerfRpm.logger.error "#{ex.backtrace.inspect}"
      ensure
        reset
      end
    end

    private

    def dispatch_events(data)
      if data && data.length > 0
        uri = URI(url)
        req = Net::HTTP::Post.new(uri.path, { "Content-Type" => "application/json", "Accept-Encoding" => "gzip", "User-Agent" => "gzip" })
        req.body = ::Oj.dump({
          "name" => configuration.application_name,
          "host" => configuration.host,
          "data" => data
        }, mode: :compat)
        res = Net::HTTP.start(uri.hostname, uri.port) do |http|
          http.read_timeout = 5
          http.request(req)
        end
        data.clear
      end
    end

    def drain(queue)
      Array.new(queue.size) { queue.pop }
    end

    def url
      ssl = configuration.ssl ? "https" : "http"
      host = configuration.host
      port = configuration.port
      license_key = configuration.license_key
      @url ||= "#{ssl}://#{host}:#{port}/api/listener/2/#{license_key}"
    end
  end
end
