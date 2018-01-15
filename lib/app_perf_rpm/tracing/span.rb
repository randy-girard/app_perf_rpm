module AppPerfRpm
  module Tracing
    class Span
      attr_accessor :operation_name

      attr_reader :context, :start_time, :end_time, :tags, :log_entries
      def initialize(context, operation_name, collector, opts = { :start_time => AppPerfRpm.now, :tags => {} })
        @context = context
        @operation_name = operation_name
        @collector = collector
        @start_time = opts[:start_time]
        @end_time = nil
        @tags = opts[:tags]
        @log_entries = []
      end

      def set_tag(key, value)
        @tags = @tags.merge(key => value)
      end

      def add_tags(tags)
        tags.each_pair do |key, value|
          set_tag(key, value)
        end
      end

      def set_baggage_item(key, value)
        @context.set_baggage_item(key, value)
      end

      def get_baggage_item(key)
        @context.get_baggage_item(key)
      end

      # Original definition for ruby 2+ was this:
      # def log(opts = { :event => nil, :timestamp => AppPerfRpm.now }, **fields)
      # but this doesn't work in 1.9.
      def log(opts = { :event => nil, :timestamp => AppPerfRpm.now }, *_, fields)
        entry = {
          "event" => opts[:event],
          "timestamp" => opts[:timestamp],
        }

        entry["fields"] = fields
        @log_entries << entry

        nil
      end

      def log_error(exception, opts = { :timestamp => AppPerfRpm.now })
        log(
          event: "error",
          timestamp: opts[:timestamp],
          message: exception.message,
          error_class: exception.class.to_s,
          backtrace: AppPerfRpm::Backtrace.clean(exception.backtrace),
          source: AppPerfRpm::Backtrace.source_extract(backtrace: exception.backtrace)
        )
      end

      def exit(opts = { :end_time => AppPerfRpm.now })
        @end_time = opts[:end_time]
      end

      def finish(opts = { :end_time => AppPerfRpm.now })
        @collector.send_span(self, @end_time || opts[:end_time])
      end
    end
  end
end
