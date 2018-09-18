# frozen_string_literal: true

module AppPerfRpm
  module Tracing
    class MetricBuffer
      def initialize
        @buffer = []
        @mutex = Mutex.new
      end

      def histogram(resolution, name, value, tags = {})
        @mutex.synchronize do
          @buffer << [resolution, name, tags, value]
          true
        end
      end

      def retrieve
        @mutex.synchronize do
          elements = @buffer.dup
          @buffer.clear
          elements
            .group_by {|e| [e[0], e[1], e[2]] }
            .map {|(resolution, name, tags), elems|
              values = elems.map {|elem| elem[3] }
              histogram = build_histogram(values)
              [resolution, name, tags, values.size, values.sum, histogram]
            }
        end
      end

      private

      def build_histogram(values)
        histogram = AppPerfRpm::Aggregate::HdrHistogram.new(values.min, values.max, 2)
        values.each {|v| histogram.recordValue(v) }
        snapshot = histogram.export
        [
          snapshot.lowestTrackableValue,
          snapshot.highestTrackableValue,
          snapshot.significantFigures,
          snapshot.counts
        ]
      end
    end
  end
end
