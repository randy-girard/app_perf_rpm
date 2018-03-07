# frozen_string_literal: true

module AppPerfRpm
  class Introspector

    VALID_RUNNERS = [
      :PhusionPassenger,
      :Puma,
      :Rainbows,
      :Resque,
      :Sidekiq,
      :Sinatra,
      :Unicorn,
      :Webrick
    ]
    class << self

      def agentable?
        if raking? || rspecing?
          AppPerfRpm.logger.info("Detected rake, not initializing agent")
          return false
        end
        AppPerfRpm.logger.info("Detecting runner...")
        VALID_RUNNERS.each do |runner|
          if const_defined?(runner.to_s)
            AppPerfRpm.logger.info("#{runner} detected. You're valid")
            return true
          end
        end
        AppPerfRpm.logger.info("No valid runner detected!")
        false
      end

      def rspecing?
        (File.basename($0) =~ /\Arspec/) == 0
      end

      def raking?
        (File.basename($0) =~ /\Arake/) == 0
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
