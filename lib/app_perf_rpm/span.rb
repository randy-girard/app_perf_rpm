module AppPerfRpm
  class Span
    attr_accessor :layer,
                  :controller,
                  :action,
                  :url,
                  :domain,
                  :type,
                  :backtrace,
                  :source,
                  :trace_id,
                  :started_at,
                  :ended_at,
                  :children,
                  :options

    def self.arrange(spans)
      spans.sort! { |a, b| (a.ended_at <=> b.ended_at) }

      null_span = Span.new
      controller = (spans.find {|s| s.controller } || null_span).controller
      action = (spans.find {|s| s.action } || null_span).action
      domain = (spans.find {|s| s.domain } || null_span).domain
      url = (spans.find {|s| s.url } || null_span).url

      while span = spans.shift
        span.controller ||= controller
        span.action ||= action
        span.domain ||= domain
        span.url ||= url

        if parent = spans.find { |n| n.parent_of?(span) }
          parent.children << span
        elsif spans.empty?
          root = span
        end
      end

      root
    end

    def initialize
      self.children = []
      self.type = "web"
      self.options = {}
    end

    def duration
      @duration ||= (ended_at - started_at) * 1000.0
    end

    def exclusive_duration
      @exclusive_duration ||= duration - children.inject(0.0) { |sum, child| sum + child.duration }
    end

    def parent_of?(span)
      start = (started_at - span.started_at) * 1000.0
      start <= 0 && (start + duration >= span.duration)
    end

    def child_of?(span)
      span.parent_of?(self)
    end

    def to_spans
      span = self.dup
      span.exclusive_duration
      span.children = []

      if children.size > 0
        return [span] + children.map(&:to_spans)
      else
        return [span]
      end
    end

    def base_options
      opts = {}
      opts["domain"] = domain
      opts["controller"] = controller
      opts["action"] =  action
      opts["url"] = url
      opts["type"] = type
      #opts["backtrace"] = ::AppPerfRpm::Backtrace.backtrace
      opts["source"] = ::AppPerfRpm::Backtrace.source_extract
      opts.delete_if { |k, v| v.nil? }
    end

    def to_s
      "#{layer}:#{trace_id}:#{started_at}:#{exclusive_duration}"
    end

    def to_a
      [
        layer,
        trace_id,
        started_at,
        duration,
        base_options.merge(options)
      ]
    end
  end
end
