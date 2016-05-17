module AppPerfRubyAgent
  class Collector
    attr_reader :store

    def initialize(store)
      @store = store
    end

    def collect_event(event)
      events.push event if AppPerfRubyAgent.collecting?
    end

    def collect
      events.clear
      AppPerfRubyAgent.collection_on
      result = yield
      AppPerfRubyAgent.collection_off
      result
    ensure
      AppPerfRubyAgent.collection_off
      store.save events.dup
      events.clear
    end

    private

    def events
      Thread.current[:app_perf_events] ||= []
    end
  end
end
