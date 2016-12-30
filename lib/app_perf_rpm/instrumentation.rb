module AppPerfRpm
  class Instrumentation
    class << self
      def load
        pattern = File.join(File.dirname(__FILE__), 'instruments', '**', '*.rb')
        Dir.glob(pattern) do |f|
          begin
            require f
          rescue => e
            AppPerfRpm.logger.error "Error loading instrumentation file '#{f}' : #{e}"
            AppPerfRpm.logger.debug "#{e.backtrace.first}"
          end
        end

        if defined? Rails::Railtie
          require "app_perf_rpm/railtie"
        end
      end
    end
  end
end
