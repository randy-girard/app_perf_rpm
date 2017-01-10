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
          :name => opts[:type],
          :query => sanitize_sql(sql),
          :database => db_opts[:database],
          :host => db_opts[:host],
          :adapter => db_opts[:adapter]
        }
      end
    end

    module SequelDatabase
      include ::AppPerfRpm::Instruments::Sequel

      def run_with_trace(sql, opts = ::Sequel::OPTS)
        if ::AppPerfRpm::Tracer.tracing?
          begin
            options = parse_opts(sql, opts)
            #options.merge!(:backtrace => ::AppPerfRpm::Backtrace.backtrace)
            #options.merge!(:source => ::AppPerfRpm::Backtrace.source_extract)
            ::AppPerfRpm::Tracer.trace("sequel", options) do
              run_without_trace(sql, opts)
            end
          rescue => e
            ::AppPerfRpm.logger.error e.inspect
            raise
          end
        else
          run_without_trace(sql, opts)
        end
      end
    end

    module SequelDataset
      include ::AppPerfRpm::Instruments::Sequel

      def execute_with_trace(sql, opts = ::Sequel::OPTS, &block)
        if ::AppPerfRpm::Tracer.tracing?
          begin
            options = parse_opts(sql, opts)
            options.merge!(::AppPerfRpm::Backtrace.backtrace_and_source_extract)
            ::AppPerfRpm::Tracer.trace("sequel", options) do
              execute_without_trace(sql, opts, &block)
            end
          rescue => e
            ::AppPerfRpm.logger.error e.inspect
            raise
          end
        else
          execute_without_trace(sql, opts, &block)
        end
      end
    end
  end
end

if defined?(::Sequel)
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
