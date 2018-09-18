# frozen_string_literal: true

module AppPerfRpm
  module Tracing
    class Collector
      attr_reader :buffer

      def initialize(local_endpoint)
        @buffer = Buffer.new
        @metrics = MetricBuffer.new
        @tags = Buffer.new()
        @local_endpoint = local_endpoint
      end

      def retrieve
        {
          "spans" => @buffer.retrieve,
          "metrics" => @metrics.retrieve,
          "tags" => @tags.retrieve
        }
      end

      def resolution(seconds = 60)
        (Time.now.utc.to_f / seconds).floor * seconds
      end

      def send_tag(key, value)
        tag = @tags.find {|tag| tag[1] == key && tag[2] == value }

        if tag
          tag[0]
        else
          index = @tags.size
          @tags << [index, key, value]
          index
        end
      end

      def send_metric(span, end_time)
        children = @buffer.children(span.context.span_id)
        children_durations = children
          .map {|child| child["duration"].to_i }
          .inject(0) {|sum, x| sum + x }

        duration = (end_time - span.start_time) * 1000

        @metrics.histogram(
          resolution,
          span.operation_name,
          (duration - children_durations).to_i,
          span.tags
        )
      end

      def send_span(span, end_time)
        if span && span.context
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
end
