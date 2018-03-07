# frozen_string_literal: true

module AppPerfRpm
  module Tracing
    class Tracer
      attr_reader :thread_span_stack, :collector

      def self.build(opts = {})
        opts[:collector] ||= nil
        opts[:sender] ||= nil
        opts[:service_name] ||= nil

        opts[:sender].start

        new(opts[:collector], opts[:sender])
      end

      def initialize(collector, sender)
        @collector = collector
        @sender = sender
      end

      def stop
        @sender.stop
      end

      def start_span(operation_name, opts = {}, *)
        child_of = opts[:child_of] || nil
        opts[:start_time] ||= AppPerfRpm.now
        opts[:tags] ||= {}

        context =
          if child_of
            parent_context = child_of.respond_to?(:context) ? child_of.context : child_of
            SpanContext.create_from_parent_context(parent_context)
          else
            SpanContext.create_parent_context
          end

        span = Span.new(context, operation_name, @collector, {
          start_time: opts[:start_time],
          tags: opts[:tags]
        })
      end

      def inject(span_context, format, carrier)
        case format
        when OpenTracing::FORMAT_TEXT_MAP
          carrier['trace-id'] = span_context.trace_id
          carrier['parent-id'] = span_context.parent_id
          carrier['span-id'] = span_context.span_id
          carrier['sampled'] = span_context.sampled? ? '1' : '0'
        when OpenTracing::FORMAT_RACK
          carrier['X-AppPerf-TraceId'] = span_context.trace_id
          carrier['X-AppPerf-ParentSpanId'] = span_context.parent_id
          carrier['X-AppPerf-SpanId'] = span_context.span_id
          carrier['X-AppPerf-Sampled'] = span_context.sampled? ? '1' : '0'
        else
          STDERR.puts "AppPerfRpm::Tracer with format #{format} is not supported yet"
        end
      end

      def extract(format, carrier)
        case format
        when OpenTracing::FORMAT_TEXT_MAP
          trace_id = carrier['trace-id']
          parent_id = carrier['parent-id']
          span_id = carrier['span-id']
          sampled = carrier['sampled'] == '1'

          create_span_context(trace_id, span_id, parent_id, sampled)
        when OpenTracing::FORMAT_RACK
          trace_id = carrier['HTTP_X_APPPERF_TRACEID']
          parent_id = carrier['HTTP_X_APPPERF_PARENTSPANID']
          span_id = carrier['HTTP_X_APPPERF_SPANID']
          sampled = carrier['HTTP_X_APPPERF_SAMPLED'] == '1'

          create_span_context(trace_id, span_id, parent_id, sampled)
        else
          STDERR.puts "AppPerfRpm::Tracer with format #{format} is not supported yet"
          nil
        end
      end

      private
      def create_span_context(trace_id, span_id, parent_id, sampled)
        if trace_id && span_id
          SpanContext.new(
            trace_id: trace_id,
            parent_id: parent_id,
            span_id: span_id,
            sampled: sampled
          )
        else
          nil
        end
      end
    end
  end
end
