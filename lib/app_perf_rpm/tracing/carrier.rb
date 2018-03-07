# frozen_string_literal: true

module AppPerfRpm
  module Tracing
    class Carrier
      def initialize
        @data = {}
      end

      def [](key)
        @data[key]
      end

      def []=(key, value)
        @data[key] = value
      end

      def each(&block)
        @data.each do |datum|
          yield(datum)
        end
      end
    end
  end
end
