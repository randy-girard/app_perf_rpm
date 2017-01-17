module AppPerfRpm
  class Tracer
    class << self
      def trace_id
        Thread.current[:trace_id]
      end

      def trace_id=(t)
        Thread.current[:trace_id] = t
      end

      def tracing?
        Thread.current[:trace_id]
      end

      def in_trace?
        !Thread.current[:trace_id].nil?
      end

      def start_instance(layer, opts = {})
        Instance.new(layer, opts)
      end

      def random_percentage
        rand * 100
      end

      def should_trace?
        random_percentage < ::AppPerfRpm.configuration.sample_rate.to_i
      end

      def start_trace(layer, opts = {})
        trace_id = opts.delete(:trace_id)
        if trace_id || should_trace?
          self.trace_id = trace_id || generate_trace_id
          result = trace(layer, opts) do
            yield
          end
          self.trace_id = nil
        else
          result = yield
        end

        result
      end

      def trace(layer, opts = {})
        result = nil

        if tracing?
          start = Time.now.to_f
          result = yield
          duration = (Time.now.to_f - start) * 1000

          event = [layer, self.trace_id, start, duration, opts]
          ::AppPerfRpm.store(event)
        else
          result = yield
        end

        result
      end

      def profile(layer, opts = {})
        if defined?(TracePoint)
          @times = {}
          traces = []
          tracer = TracePoint.new(:call, :return) do |tp|
            backtrace = caller(0)
            key = "#{tp.defined_class}_#{tp.method_id}_#{backtrace.size}"
            if tp.event == :call
              @times[key] = Time.now.to_f
            else
              if @times[key]
                @times[key] = Time.now.to_f - @times[key].to_f
                traces << {
                  :duration => @times[key].to_f,
                  :class => tp.defined_class,
                  :method => tp.method_id,
                  :backtrace => backtrace,
                  :line => ::AppPerfRpm::Backtrace.send(:clean_line, tp.path),
                  :line_number => tp.lineno
                }
              end
            end
          end

          result = tracer.enable { yield }
          @times = {}

          return traces, result
        else
          return [], yield
        end
      end

      def log_event(event, opts = {})
        ::AppPerfRpm.store([event, generate_trace_id, Time.now.to_f, opts])
      end

      def generate_trace_id
        Digest::SHA1.hexdigest([Time.now, rand].join)
      end

      class Instance
        attr_accessor :layer, :opts, :start, :duration

        def initialize(layer, opts = {})
          self.layer = layer
          self.opts = opts
          self.start = Time.now.to_f
        end

        def finish(opts = {})
          self.opts.merge!(opts)
          self.duration = (Time.now.to_f - start) * 1000
        end

        def submit(opts = {})
          if ::AppPerfRpm::Tracer.tracing?
            self.opts.merge!(opts)
            ::AppPerfRpm.store([layer, trace_id, start, duration, opts])
          end
        end

        private

        def trace_id
          ::AppPerfRpm::Tracer.trace_id
        end
      end
    end
  end
end
