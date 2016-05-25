module AppPerfRubyAgent
  module Instrument
    class ActionMailer < AppPerfRubyAgent::Instrument::Base

      def initialize
        super /\.action_mailer$/
      end

      def active?
        true
      end

      def prepare(event)
        event.payload[:backtrace] = AppPerfRubyAgent.clean_trace
        event.payload.except!(:mail)
      end

    end
  end
end
