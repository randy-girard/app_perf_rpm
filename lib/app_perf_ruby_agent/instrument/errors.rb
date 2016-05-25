module AppPerfRubyAgent
  module Instrument
    class Errors < AppPerfRubyAgent::Instrument::Base

      def initialize
        super /^app\.errors$/
      end

      def active?
        true
      end

      def prepare(event)
      end

    end
  end
end
