# frozen_string_literal: true

module AppPerfRpm
  class Tracer
    class << self
      # This method should be called by any components that are
      # capable of starting the tracing process.
      # ie. rack, sidekiq worker, etc
      def sample!(incoming_trace = nil, force = false)
        # Since we keep track of the active span, meaning we have entered into
        # tracing at some point, and we no longer have an active span,
        # reset tracing.
        sample_off! if !AppPerfRpm.tracer.active_span

        # Now determine if we want to trace, either by an incoming
        # trace or meeting the sample rate.
        Thread.current[:sample] = force || !!incoming_trace || should_sample?
        Thread.current[:sample]
      end

      def sample_off!
        Thread.current[:sample] = false
      end

      def sampled?
        !!Thread.current[:sample]
      end

      def tracing?
        AppPerfRpm.tracing? && sampled?
      end

      def random_percentage
        rand * 100
      end

      def should_sample?
        random_percentage <= ::AppPerfRpm.config.sample_rate.to_i
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
                  "duration "=> @times[key].to_f,
                  "class" => tp.defined_class,
                  "method" => tp.method_id,
                  "backtrace" => backtrace,
                  "line" => ::AppPerfRpm::Backtrace.send(:clean_line, tp.path),
                  "line_number" => tp.lineno
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
    end
  end
end
