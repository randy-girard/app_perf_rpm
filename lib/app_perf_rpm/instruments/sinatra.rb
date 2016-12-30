module AppPerfRpm
  module Instruments
    module Sinatra
      def dispatch_with_trace
        opts = {
          :controller => self.class.to_s,
          :action => env["PATH_INFO"]
        }

        opts.merge!(:backtrace => ::AppPerfRpm.clean_trace)

        ::AppPerfRpm::Tracer.trace("sinatra", opts) do
          dispatch_without_trace
        end
      end

      def handle_exception_with_trace(boom)
        handle_exception_without_trace(boom)
      end
    end
  end
end

if defined?(::Sinatra)
  ::AppPerfRpm.logger.info "Initializing sinatra tracer."

  ::Sinatra::Base.use AppPerfRpm::Instruments::Rack

  unless defined?(::Padrino)
    ::Sinatra::Base.send(:include, ::AppPerfRpm::Instruments::Sinatra)
    ::Sinatra::Base.class_eval do
      alias_method :dispatch_without_trace, :dispatch!
      alias_method :dispatch!, :dispatch_with_trace
      alias_method :handle_exceptio_without_trace, :handle_exception!
      alias_method :handle_exception!, :handle_exception_with_trace
    end
  end
end
