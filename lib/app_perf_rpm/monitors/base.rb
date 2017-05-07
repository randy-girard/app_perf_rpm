module AppPerfRpm
  module Monitors
    class Base
      def self.descendants
        @descendants ||= ObjectSpace.each_object(Class).select { |klass| klass < self }
      end

      def initialize
        reset
      end

      def value
        raise NotImplementedError
      end

      def name
        raise NotImplementedError
      end

      def unit
        raise NotImplementedError
      end

      def reset
        @data = []
      end

      def record
        @data << [Time.now, value]
      end

      def queue_for_dispatching
        events = @data
          .group_by { |datum| AppPerfRpm.floor_time(datum[0], 60) }
          .map { |k, v| [k, v.map(&:last)] }
          .to_h

        events.each_pair do |timestamp, values|
          sum = values.inject(0){ |sum, x| sum + x }
          average_value = 0
          average_value = sum / values.size if values.size.to_i > 0
          ::AppPerfRpm.store([
              "metric",
              timestamp.to_f,
              {
                "name" => name,
                "value" => average_value,
                "unit" => unit
              }
            ]
          )
        end
      end

      def logged?
        !!@logged
      end
    end
  end
end
