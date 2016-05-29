require 'zlib'
require 'json'
require 'net/http'

module AppPerfRubyAgent
  class Store

    class VoidInstrumenter < ::ActiveSupport::Notifications::Instrumenter
      def instrument(name, payload={})
        yield(payload) if block_given?
      end
    end

    def initialize
      @queue = Queue.new
      @worker_mutex = Mutex.new
    end

    def save(events)
      ensure_worker_running
      return if events.empty?
      @queue << events
    end

    def ensure_worker_running
    return if worker_running?
      @worker_mutex.synchronize do
        return if worker_running?
        initialize_dispatcher
      end
    end

    def reset
      @queue.clear
      @start_time = Time.now
    end

    def ready?
      Time.now > @start_time + 60 && !@queue.empty?
    end

    def worker_running?
      @worker_thread && @worker_thread.alive?
    end

    def initialize_dispatcher
      @worker_thread = Thread.new do
        set_void_instrumenter
        reset
        loop do
          begin
            AppPerfRubyAgent.probes.each(&:on_loop)

            if ready?
              process_data
              dispatch_events(:analytic_event_data)
              dispatch_events(:transaction_sample_data)
              dispatch_events(:transaction_data)
              dispatch_events(:error_data)
              reset
            end
          rescue => ex
            puts "ERROR: #{ex.inspect}"
            puts "#{ex.backtrace.inspect}"
            STDOUT.flush
          end
          sleep 5
        end
      end
      @worker_thread.abort_on_exception = true
    end

    private

    def set_void_instrumenter
      Thread.current[:"instrumentation_#{notifier.object_id}"] = VoidInstrumenter.new(notifier)
    end

    def analytic_event_data
      Thread.current[:app_perf_analytic_event_data] ||= []
    end

    def transaction_sample_data
      Thread.current[:app_perf_transaction_sample_data] ||= []
    end

    def transaction_data
      Thread.current[:app_perf_transaction_data] ||= []
    end

    def error_data
      Thread.current[:app_perf_error_data] ||= []
    end

    def memory_data
      Thread.current[:app_perf_memory_data] ||= []
    end

    def notifier
      ActiveSupport::Notifications.notifier
    end

    def process_data
      all_events = []

      while @queue.size > 0
        events = @queue.pop

        end_point = nil
        if (event = events.find {|e| e.payload[:end_point] })
          end_point = event.payload[:end_point]
        end
        if end_point
          events.each {|e| e.payload[:end_point] = end_point }
        end

        root_event = AppPerfRubyAgent::NestedEvent.arrange(events.dup, :presort => false)
        if root_event.sample && root_event.duration > AppPerfRubyAgent.config.sample_threshold
          transaction_sample_data.push root_event.to_hash
        end

        events.select {|e| e.category.eql?("error") }.each do |event|
          error_data << event.to_hash
        end
        all_events += events.dup
      end

      all_events.group_by {|e| [e.payload[:end_point], AppPerfRubyAgent.round_time(e.timestamp, 60)] }.each_pair do |group, grouped_events|
        if group[0]

          middleware_calls = grouped_events.select {|e| event_name(e) == "Middleware" }
          app_calls = grouped_events.select {|e| event_name(e) == "App" }
          view_calls = grouped_events.select {|e| event_name(e) == "View" }
          db_calls = grouped_events.select {|e| event_name(e) == "Database" }
          gc_calls = grouped_events.select {|e| event_name(e) == "GC Execution" }

          durations = grouped_events.map(&:exclusive_duration)
          total_duration = durations.inject(0){|sum,x| sum + x }

          transaction_data << {
            :end_point => group[0],
            :timestamp => group[1],
            :call_count => durations.size,
            :duration => total_duration,
            :avg => total_duration / durations.size.to_f,
            :min => durations.min,
            :max => durations.max,
            :sum_sqr => durations.inject {|sum, item| sum + item*item },
            :app_call_count => app_calls.size,
            :app_duration => app_calls.map(&:exclusive_duration).inject(0){|sum,x| sum + x },
            :view_call_count => view_calls.size,
            :view_duration => view_calls.map(&:exclusive_duration).inject(0){|sum,x| sum + x },
            :middleware_call_count => middleware_calls.size,
            :middleware_duration => middleware_calls.map(&:exclusive_duration).inject(0){|sum,x| sum + x },
            :db_call_count => db_calls.size,
            :db_duration => db_calls.map(&:exclusive_duration).inject(0){|sum,x| sum + x },
            :gc_call_count => gc_calls.size,
            :gc_duration => gc_calls.map(&:exclusive_duration).inject(0){|sum,x| sum + x }
          }
        end
      end

      error_data.group_by {|e| AppPerfRubyAgent.round_time(e[:timestamp], 60) }.each_pair do |timestamp, events|
        analytic_event_data << {
          :name => "Error",
          :timestamp => timestamp,
          :value => events.size
        }
      end

      all_events.select {|e| e.category.eql?("memory") }.group_by {|e| AppPerfRubyAgent.round_time(e.timestamp, 60) }.each_pair do |timestamp, events|
        analytic_event_data << {
          :name => "Memory",
          :timestamp => timestamp,
          :value => events.map(&:duration).inject(0){|sum,x| sum + x }
        }
      end
    end

    def event_name(event)
      case event.category
      when "rack"
        "Middleware"
      when "action_controller", "sinatra"
        "App"
      when "active_record", "sequel"
        "Database"
      when "action_view", "tilt"
        "View"
      when "gc"
        "GC Execution"
      when "memory"
        "Memory Usage"
      when "error"
        "Error"
      else
        nil
      end
    end

    def url(method)
      @url ||= {}
      @url[method] ||= [
        AppPerfRubyAgent.config.ssl ? "https" : "http",
        "://",
        AppPerfRubyAgent.config.host,
        ":",
        AppPerfRubyAgent.config.port,
        "/api/listener/1/#{AppPerfRubyAgent.config.license_key}/#{method}"
      ].join
    end

    def dispatch_events(method)
      data = send(method)
      if data && data.length > 0
        uri = URI(url(method))
        req = Net::HTTP::Post.new(uri, { "Content-Type" => "application/json", "Accept-Encoding" => "gzip", "User-Agent" => "gzip" })
        req.body = {
          "host" => AppPerfRubyAgent.config.host,
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
