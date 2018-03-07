# frozen_string_literal: true

module AppPerfRpm
  module Tracing
    class ManagedTracer
      extend Forwardable
      def_delegators :@tracer, :inject, :extract

      attr_reader :thread_span_stack

      def initialize(tracer, thread_span_stack = ThreadSpanStack.new)
        @tracer = tracer
        @thread_span_stack = thread_span_stack
      end

      def wrapped
        @tracer
      end

      def collector
        @tracer.collector
      end

      def active_span
        thread_span_stack.active_span
      end

      def start_span(operation_name, opts = {}, *args)
        opts[:child_of] ||= active_span

        span = @tracer.start_span(operation_name, opts, *args)
        @thread_span_stack.set_active_span(span)
      end
    end
  end
end
