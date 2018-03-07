# frozen_string_literal: true

module AppPerfRpm
  module Tracing
    class ThreadSpanStack
      def set_active_span(span)
        active_span = ManagedSpan.new(span, method(:pop))
        push(active_span)
        active_span
      end

      def active_span
        local_stack.last
      end

      def clear
        local_stack.clear
      end

    private
      def push(span)
        local_stack << span
      end

      def pop
        local_stack.pop
      end

      def local_stack
        Thread.current[:__active_span__] ||= []
      end
    end
  end
end
