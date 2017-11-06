module AppPerfRpm
  module Tracing
    class SpanContext
      def self.create_parent_context
        trace_id = TraceId.generate
        new(trace_id: trace_id, span_id: trace_id, sampled: true)
      end

      def self.create_from_parent_context(span_context)
        new(
          span_id: TraceId.generate,
          parent_id: span_context.span_id,
          trace_id: span_context.trace_id,
          sampled: span_context.sampled?
        )
      end

      attr_reader :span_id, :parent_id, :trace_id, :baggage

      def initialize(span_id:, parent_id: nil, trace_id:, sampled:, baggage: {})
        @span_id = span_id
        @parent_id = parent_id
        @trace_id = trace_id
        @sampled = sampled
        @baggage = baggage
      end

      def set_baggage_item(key, value)
        baggage[key] = value
      end

      def get_baggage_item(key)
        baggage[key]
      end

      def sampled?
        @sampled
      end
    end
  end
end
