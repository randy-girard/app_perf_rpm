module AppPerfRpm
  module Instruments
    module EmqueConsuming
      module Router
        def route_with_trace(topic, type, message)
          action = type.to_s.split(".").last

          opts = {
            :controller => topic,
            :action => action,
            :url => "/#{topic}/#{action}",
            :domain => Socket.gethostname
          }

          opts[:backtrace] = ::AppPerfRpm::Backtrace.backtrace
          opts[:source] = ::AppPerfRpm::Backtrace.source_extract

          ::AppPerfRpm::Tracer.start_trace("emque-consuming", opts) do
            route_without_trace(topic, type, message)
          end
        end
      end
    end
  end
end

if defined?(Emque::Consuming)
  AppPerfRpm.logger.info "Initializing emque-consuming tracer."

  Emque::Consuming::Router.send(:include, AppPerfRpm::Instruments::EmqueConsuming::Router)

  Emque::Consuming::Router.class_eval do
    alias_method :route_without_trace, :route
    alias_method :route, :route_with_trace
  end
end
