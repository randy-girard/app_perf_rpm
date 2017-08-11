require 'digest/md5'

module AppPerfRpm
  class Aggregator
    def initialize
    end

    def aggregate(traces)
      metrics = []
      traces = arrange_traces(traces)
      spans = traces_to_spans(traces)
      spans_by_time(spans).each_pair do |time, spans|
        group_spans(spans).each_pair do |(type, layer, domain, url, controller, action), grouped_spans|
          opts = {}
          opts["type"] = type if type
          opts["layer"] = layer if layer
          opts["domain"] = domain if domain
          opts["url"] = url if url
          opts["controller"] = controller if controller
          opts["action"] = action if action
          metrics << build_metric("trace.web.request.duration", time, grouped_spans, opts)
        end
      end

      return metrics
    end

    private

    def build_metric(metric_name, time, spans, opts)
      num_spans = spans.uniq(&:trace_id).size
      durations = spans.inject(0.0) {|s, x| s + x.exclusive_duration }.to_f
      hits = spans.size

      tags = {
        "traces" => num_spans,
        "hits" => hits
      }.merge(opts)

      ["metric", time.to_f, metric_name, durations, tags]
    end

    def arrange_traces(traces)
      traces
        .group_by(&:trace_id)
        .map {|span| Span.arrange(span.last.dup) }
    end

    def traces_to_spans(traces)
      traces
        .map {|trace| trace.to_spans}
        .flatten
    end

    def spans_by_time(spans)
      spans.group_by {|span|
        AppPerfRpm.floor_time(Time.at(span.started_at), dispatch_interval)
      }
    end

    def group_spans(spans)
      spans
        .group_by {|span| [
          span.type,
          span.layer,
          span.domain,
          span.url,
          span.controller,
          span.action
        ]}
    end

    def dispatch_interval
      30
    end
  end
end
