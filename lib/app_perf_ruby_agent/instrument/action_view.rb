module AppPerfRubyAgent
  module Instrument
    class ActionView < AppPerfRubyAgent::Instrument::Base

      def initialize
        super /\.action_view$/
      end

      def active?
        true
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
        event.payload[:backtrace] = clean_trace
      end

    end
  end
end
