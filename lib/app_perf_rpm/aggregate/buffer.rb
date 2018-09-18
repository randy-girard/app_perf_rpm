# frozen_string_literal: true

module AppPerfRpm
  module Aggregate
    class Buffer
      def initialize
        @buffer = {}
        @mutex = Mutex.new
      end

      def increment!(resolution, operation_name, tags: {})
        @mutex.synchronize do
          @buffer[resolution] ||= {}
          @buffer[resolution][operation_name] ||= {}
          @buffer[resolution][operation_name]["count"] ||= 0
          @buffer[resolution][operation_name]["count"] += 1

          if tags
            @buffer[resolution][operation_name]["tags"] ||= {}
            @buffer[resolution][operation_name]["tags"].merge!(tags)
          end

          true
        end
      end

      def retrieve
        @mutex.synchronize do
          elements = @buffer.dup
          @buffer = {}
          elements
        end
      end
    end
  end
end
