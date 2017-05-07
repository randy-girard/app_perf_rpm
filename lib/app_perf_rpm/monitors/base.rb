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
        @logged = false
      end

      def log
        if !logged?
          ::AppPerfRpm.store(event)
        end
      end

      def logged?
        !!@logged
      end

      def event
        [
          "metric",
          AppPerfRpm.floor_time(Time.now, 60).to_f,
          {
            "name" => name,
            "value" => value,
            "unit" => unit
          }
        ]
      end
    end
  end
end
