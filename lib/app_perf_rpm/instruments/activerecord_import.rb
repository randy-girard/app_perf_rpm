# frozen_string_literal: true

module AppPerfRpm
  module Instruments
    module ActiveRecordImport
      include AppPerfRpm::Utils

      def insert_many_with_trace( sql, values, *args )
        if ::AppPerfRpm::Tracer.tracing?
          sql_copy = sql.dup
          base_sql, post_sql = if sql_copy.dup.is_a?( String )
            [sql_copy, '']
          elsif sql.is_a?( Array )
            [sql_copy.shift, sql_copy.join( ' ' )]
          end

          adapter = connection_config.fetch(:adapter)
          sanitized_sql = sanitize_sql(base_sql + values.join( ',' ) + post_sql, adapter)

          span = AppPerfRpm.tracer.start_span(self.class.name || 'sql.query', tags: {
            "component" => "ActiveRecordImport",
            "span.kind" => "client",
            "db.statement" => sanitized_sql,
            "db.user" => connection_config.fetch(:username, 'unknown'),
            "db.instance" => connection_config.fetch(:database),
            "db.vendor" => adapter,
            "db.type" => "sql"
          })
          AppPerfRpm::Utils.log_source_and_backtrace(span, :active_record_import)
        end

        insert_many_without_trace(sql, values, *args)
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


if ::AppPerfRpm.config.instrumentation[:active_record_import][:enabled] &&
  defined?(ActiveRecord::Import::PostgreSQLAdapter)
  AppPerfRpm.logger.info "Initializing activerecord-import tracer."

  ActiveRecord::Import::PostgreSQLAdapter.send(:include, AppPerfRpm::Instruments::ActiveRecordImport)

  ActiveRecord::Import::PostgreSQLAdapter.class_eval do
    alias_method :insert_many_without_trace, :insert_many
    alias_method :insert_many, :insert_many_with_trace
  end
end
