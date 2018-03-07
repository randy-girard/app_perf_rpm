# frozen_string_literal: true

module AppPerfRpm
  module Instruments
    module EmqueConsuming
      module Router
        def route_with_trace(topic, type, message)
          action = type.to_s.split(".").last

          span = ::AppPerfRpm.tracer.start_span("#{topic}##{action}", tags: {
            "component" => "EmqueConsuming",
            "http.url" => "/#{topic}/#{action}",
            "peer.address" => Socket.gethostname
          })
          AppPerfRpm::Utils.log_source_and_backtrace(span, :emque_consuming)

          route_without_trace(topic, type, message)
        rescue Exception => e
          if span
            span.set_tag('error', true)
            span.log_error(e)
          end
          raise
        ensure
          span.finish if span
        end
      end
    end
  end
end

if ::AppPerfRpm.config.instrumentation[:emque_consuming][:enabled] && defined?(Emque::Consuming)
  AppPerfRpm.logger.info "Initializing emque-consuming tracer."

  Emque::Consuming::Router.send(:include, AppPerfRpm::Instruments::EmqueConsuming::Router)

  Emque::Consuming::Router.class_eval do
    alias_method :route_without_trace, :route
    alias_method :route, :route_with_trace
  end
end
