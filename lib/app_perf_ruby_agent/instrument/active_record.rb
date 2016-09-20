module AppPerfRubyAgent
  module Instrument
    class ActiveRecord < AppPerfRubyAgent::Instrument::Base

      def initialize
        super /\.active_record$/
      end

      def active?
        true
      end

      def ignore?(event)
        event.payload[:sql] !~ /^(SELECT|INSERT|UPDATE|DELETE)/
      end

      def prepare(event)
        event.payload[:adapter] = ::ActiveRecord::Base.connection.adapter_name
        event.payload[:sql] = event.payload[:sql].squeeze(" ")
        event.payload[:backtrace] = AppPerfRubyAgent.clean_trace
        event.payload.delete(:connection_id)
        event.payload.delete(:binds)
      end

    end
  end
end
