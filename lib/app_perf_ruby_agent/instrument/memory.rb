module AppPerfRubyAgent
  module Instrument
    class Memory < AppPerfRubyAgent::Instrument::Base

      def initialize
        super /^app\.memory$/
      end

      def active?
        true
      end

      def sample?
        false
      end

      def ignore?(event)
        event.name != 'app.memory'
      end

      def prepare(event)
        event.sample = false
        event.duration = event.payload[:value].to_f
      end

    end
  end
end
