require 'yaml'

module AppPerfRpm
  class Configuration
    attr_accessor :host,
                  :port,
                  :license_key,
                  :ssl,
                  :sample_rate,
                  :sample_threshold,
                  :application_name

    def initialize
      self.host = default_if_blank(ENV["APP_PERF_HOST"], "localhost")
      self.port = default_if_blank(ENV["APP_PERF_PORT"], 5000)
      self.ssl = false
      self.license_key = default_if_blank(ENV["APP_PERF_LICENSE_KEY"], nil)
      self.application_name = "Default"
      self.sample_rate = 10 # Percentage of request to sample
      self.sample_threshold = 0 # Minimum amount of duration to sample
    end

    private

    def default_if_blank(value, default)
      value.blank? ? default : value
    end
  end
end
