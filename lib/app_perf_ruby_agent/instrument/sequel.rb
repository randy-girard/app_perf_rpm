module AppPerfRubyAgent
  module Instrument
    class Sequel < AppPerfRubyAgent::Instrument::Base
      def initialize
        super /\.sequel/
      end

      def active?
        true
      end

      def ignore?(event)
        event.payload[:sql] !~ /^(SELECT|INSERT|UPDATE|DELETE)/
      end

      def prepare(event)
        event.payload[:sql] = event.payload[:sql].squeeze(" ")
        event.payload[:backtrace] = AppPerfRubyAgent.clean_trace
        event.payload.delete(:connection_id)
        event.payload.delete(:binds)
      end

    end
  end
end
