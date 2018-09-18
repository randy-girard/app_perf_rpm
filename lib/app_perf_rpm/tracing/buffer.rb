# frozen_string_literal: true

module AppPerfRpm
  module Tracing
    class Buffer
      def initialize
        @buffer = []
        @mutex = Mutex.new
      end

      def <<(element)
        @mutex.synchronize do
          @buffer << element
          true
        end
      end

      def children(parent_id)
        @mutex.synchronize do
          @buffer.select {|b|
            b["parentId"] == parent_id
          }
        end
      end

      def find
        @mutex.synchronize do
          @buffer.find {|buffer| yield buffer }
        end
      end

      def size
        @mutex.synchronize do
          @buffer.size
        end
      end

      def retrieve
        @mutex.synchronize do
          elements = @buffer.dup
          @buffer.clear
          elements
        end
      end
    end
  end
end
