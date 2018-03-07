# frozen_string_literal: true

module AppPerfRpm
  module Tracing
    class ManagedSpan < Span
      extend Forwardable

      def_delegators :@span, :context, :operation_name=, :set_tag, :set_baggage_item, :get_baggage_item, :log, :finish

      def initialize(span, deactivate)
        @span = span
        @deactivate = deactivate.respond_to?(:call) ? deactivate : nil
        @active = true
      end

      def wrapped
        @span
      end

      def active?
        @active
      end

      def deactivate
        if @active && @deactivate
          deactivated_span = @deactivate.call
          warn "ActiveSpan::SpanSource inconsistency found during deactivation" unless deactivated_span == self
          @active = false
        end
      end

      def finish(opts = {})
        opts[:end_time] ||= AppPerfRpm.now

        deactivate
        @span.finish(end_time: opts[:end_time])
      end
    end
  end
end
