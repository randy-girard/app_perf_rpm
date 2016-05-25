module AppPerfRubyAgent
  module Instrument
    class Sinatra < AppPerfRubyAgent::Instrument::Base
      def initialize
        super /\.sinatra$/
      end

      def active?
        true
      end

      def ignore?(event)
        event.name != 'process_action.sinatra'
      end

      def prepare(event)
        event.payload[:backtrace] = AppPerfRubyAgent.clean_trace
        event.payload[:end_point] = "#{event.payload.delete(:controller)}##{event.payload.delete(:action)}"
        event.payload.slice!(:path, :method, :params, :db_runtime, :view_runtime, :end_point)
      end

    end
  end
end
