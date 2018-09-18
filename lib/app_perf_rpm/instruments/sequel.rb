# frozen_string_literal: true

module AppPerfRpm
  module Instruments
    module Sequel
      def sanitize_sql(sql)
        regexp = Regexp.new('(\'[\s\S][^\']*\'|\d*\.\d+|\d+|NULL)', Regexp::IGNORECASE)
        sql.to_s.gsub(regexp, '?')
      end

      def parse_opts(sql, opts)
        if ::Sequel::VERSION < '3.41.0' && !(self.class.to_s =~ /Dataset$/)
          db_opts = @opts
        elsif @pool
          db_opts = @pool.db.opts
        else
          db_opts = @db.opts
        end

        if ::Sequel::VERSION > '4.36.0' && !sql.is_a?(String)
          # In 4.37.0, sql was converted to a prepared statement object
          sql = sql.prepared_sql unless sql.is_a?(Symbol)
        end

        {
          "type" => opts[:type],
          "statement" => sanitize_sql(sql),
          "instance" => db_opts[:database],
          "user" => db_opts[:user],
          "vendor" => db_opts[:adapter],
          "address" => db_opts[:host],
          "port" => db_opts[:port]
        }
      end
    end

    module SequelDatabase
      include ::AppPerfRpm::Instruments::Sequel

      def run_with_trace(sql, options = ::Sequel::OPTS)
        span = ::AppPerfRpm.tracer.start_span(tags: parse_opts(sql, options))
        span.set_tag "component", "Sequel"
        span.log_source_and_backtrace(:sequel)

        run_without_trace(sql, options)
      rescue Exception => e
        if span
          span.set_tag('error', true)
          span.log_error(e)
        end
        raise
      ensure
        span.finish if span
      end
    end

    module SequelDataset
      include ::AppPerfRpm::Instruments::Sequel

      def execute_with_trace(sql, options = ::Sequel::OPTS, &block)
        span = ::AppPerfRpm.tracer.start_span(tags: parse_opts(sql, options))
        span.set_tag "component", "Sequel"
        span.log_source_and_backtrace(:sequel)

        execute_without_trace(sql, options, &block)
      rescue Exception => e
        if span
          span.set_tag('error', true)
          span.log_error(e)
        end
        raise
      ensure
        span.finish if span
      end
    end
  end
end

if ::AppPerfRpm.config.instrumentation[:sequel][:enabled] && defined?(::Sequel)
  ::AppPerfRpm.logger.info "Initializing sequel tracer."

  ::Sequel::Database.send(:include, AppPerfRpm::Instruments::SequelDatabase)
  ::Sequel::Dataset.send(:include, AppPerfRpm::Instruments::SequelDataset)

  ::Sequel::Database.class_eval do
    alias_method :run_without_trace, :run
    alias_method :run, :run_with_trace
  end

  ::Sequel::Dataset.class_eval do
    alias_method :execute_without_trace, :execute
    alias_method :execute, :execute_with_trace
  end
end
