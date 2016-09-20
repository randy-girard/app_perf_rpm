module AppPerfRubyAgent
  module Instrument
    class Nginx < AppPerfRubyAgent::Instrument::Base

      def initialize
        super /^web.nginx$/
      end

      def active?
        true
      end

      def ignore?(event)
        event.name != 'web.nginx'
      end

      def prepare(event)
        event.duration = Time.now - Time.at(event.payload[:trace_start].to_i)
      end

    end
  end
end
