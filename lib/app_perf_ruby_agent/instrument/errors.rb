module AppPerfRubyAgent
  module Instrument
    class Errors < AppPerfRubyAgent::Instrument::Base

      def initialize
        super /^ruby\.errors$/
      end

      def active?
        true
      end

      def prepare(event)
      end

    end
  end
end
