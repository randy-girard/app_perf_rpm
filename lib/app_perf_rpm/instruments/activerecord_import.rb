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

          adapter = ::ActiveRecord::Base.connection_config[:adapter]

          sanitized_sql = sanitize_sql(base_sql + values.join( ',' ) + post_sql, adapter)

          AppPerfRpm::Tracer.trace('activerecord') do |span|
            span.options = {
              "adapter" => adapter,
              "query" => sanitized_sql,
              "name" => self.class.name
            }

            insert_many_without_trace(sql, values, *args)
          end
        else
          insert_many_without_trace(sql, values, *args)
        end
      end
    end
  end
end


if ::AppPerfRpm.configuration.instrumentation[:active_record_import][:enabled] &&
  defined?(ActiveRecord::Import::PostgreSQLAdapter)
  AppPerfRpm.logger.info "Initializing activerecord-import tracer."

  ActiveRecord::Import::PostgreSQLAdapter.send(:include, AppPerfRpm::Instruments::ActiveRecordImport)

  ActiveRecord::Import::PostgreSQLAdapter.class_eval do
    alias_method :insert_many_without_trace, :insert_many
    alias_method :insert_many, :insert_many_with_trace
  end
end
