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

      def interval
        raise NotImplementedError
      end

      def unit
        raise NotImplementedError
      end

      def tick
        if ready?
          log
          reset
        end
      end

      def log
        ::AppPerfRpm.store(event)
      end

      def event
        ["metric", Time.now.to_f, { :name => name, :value => value, :unit => unit }]
      end

      def reset
        @start_time = Time.now
      end

      def ready?
        Time.now > @start_time + interval
      end
    end
  end
end
