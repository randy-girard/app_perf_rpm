module AppPerfRpm
  module Instruments
    module ActiveRecordImport
      include AppPerfRpm::Utils

      def insert_many_with_trace( sql, values, *args )
        if ::AppPerfRpm.tracing?
          sql_copy = sql.dup
          base_sql, post_sql = if sql_copy.dup.is_a?( String )
            [sql_copy, '']
          elsif sql.is_a?( Array )
            [sql_copy.shift, sql_copy.join( ' ' )]
          end

          sanitized_sql = sanitize_sql(base_sql + values.join( ',' ) + post_sql)

          opts = {
            :adapter => ::ActiveRecord::Base.connection_config[:adapter],
            :sql => sanitized_sql,
            :name => self.class.name
          }

          opts.merge!(:backtrace => ::AppPerfRpm::Backtrace.backtrace)
          opts.merge!(:source => ::AppPerfRpm::Backtrace.source_extract)

          AppPerfRpm::Tracer.trace('activerecord', opts) do
            insert_many_without_trace(sql, values, *args)
          end
        else
          insert_many_without_trace(sql, values, *args)
        end
      end
    end
  end
end


if defined?(ActiveRecord::Import::PostgreSQLAdapter)
  AppPerfRpm.logger.info "Initializing activerecord-import tracer."

  ActiveRecord::Import::PostgreSQLAdapter.send(:include, AppPerfRpm::Instruments::ActiveRecordImport)

  ActiveRecord::Import::PostgreSQLAdapter.class_eval do
    alias_method :insert_many_without_trace, :insert_many
    alias_method :insert_many, :insert_many_with_trace
  end
end
