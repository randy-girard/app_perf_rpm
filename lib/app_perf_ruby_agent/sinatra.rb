if defined?(::Sinatra)
  module AppPerfRubyAgent
    require 'app_perf_ruby_agent'
    require 'app_perf_ruby_agent/app'

    class << ::Sinatra::Base
      alias build_without_sk build

      def build(*args, &block)
       agent = AppPerfRubyAgent::App.new
        agent.setup(".")
        agent.subscribe
        self.use AppPerfRubyAgent::Middleware, agent.collector, []

        build_without_sk(*args, &block)
      end
    end
  end
end