module AppPerfRubyAgent
  module Instrument
    class Rack < AppPerfRubyAgent::Instrument::Base

      def initialize
        super /^request\.rack$/
      end

      def active?
        true
      end

    end
  end
end
