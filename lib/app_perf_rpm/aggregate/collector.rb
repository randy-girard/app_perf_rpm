# frozen_string_literal: true

module AppPerfRpm
  module Aggregate
    class Collector
      attr_reader :buffer

      def initialize
        @buffer = Buffer.new
      end

      def retrieve
        @buffer.retrieve
      end

      def resolution(seconds = 60)
        (Time.now.utc.to_f / seconds).floor * seconds
      end

      def increment!(operation_name, tags: nil)
        @buffer.increment!(resolution, operation_name, tags: tags)
      end
    end
  end
end
