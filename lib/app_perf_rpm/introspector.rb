module AppPerfRpm 
  class Introspector

    VALID_RUNNERS = %w(Puma Unicorn Sidekiq Sinatra Resque Webbrick)
    class << self

      def agentable?
        AppPerfRpm.logger.info("Detecting runner...")
        VALID_RUNNERS.each do |runner| 
          if const_defined?(runner)
            AppPerfRpm.logger.info("#{runner} detected. You're valid")
            return true
          end
        end
        AppPerfRpm.logger.info("No valid runner detected!")
        false
      end

      def const_defined?(string_const)
        begin
        Object.const_get(string_const)
          true
        rescue NameError
          false
        end
      end

    end
  end
end
