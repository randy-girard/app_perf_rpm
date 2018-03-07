# frozen_string_literal: true

module AppPerfRpm
  module Tracing
    class Collector
      attr_reader :buffer

      def initialize(local_endpoint)
        @buffer = Buffer.new
        @local_endpoint = local_endpoint
      end

      def retrieve
        @buffer.retrieve
      end

      def send_span(span, end_time)
        duration = end_time - span.start_time

        @buffer << {
          "traceId" => span.context.trace_id,
          "id" => span.context.span_id,
          "parentId" => span.context.parent_id,
          "name" => span.operation_name,
          "timestamp" => span.start_time,
          "duration" => duration * 1_000,
          "logEntries" => span.log_entries,
          "tags" => span.tags
        }
      end
    end
  end
end
