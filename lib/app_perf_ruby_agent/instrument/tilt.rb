module AppPerfRubyAgent
  module Instrument
    class Tilt < AppPerfRubyAgent::Instrument::Base
      def initialize
        super /\.tilt/
      end

      def active?
        true
      end

      def ignore?(event)
        event.name != 'render.tilt'
      end

      def prepare(event)
        event.payload.each do |key, value|
          case value
          when NilClass
          when String
            event.payload[key] = prune_path(value)
          else
            event.payload[key] = value
          end
        end
        event.payload[:backtrace] = AppPerfRubyAgent.clean_trace
      end
    end
  end
end
