# frozen_string_literal: true

module AppPerfRpm
  module Instruments
    module ActiveRecord
      module Adapters
        module Mysql2
          include AppPerfRpm::Utils

          IGNORE_STATEMENTS = {
            "SCHEMA" => true,
            "EXPLAIN" => true,
            "CACHE" => true
          }

          def ignore_trace?(name)
            IGNORE_STATEMENTS[name.to_s] ||
              (name && name.to_sym == :skip_logging) ||
              name == 'ActiveRecord::SchemaMigration Load'
          end

          def execute_with_trace(sql, name = nil)
            if ::AppPerfRpm::Tracer.tracing?
              unless ignore_trace?(name)
                adapter = connection_config.fetch(:adapter)
                sanitized_sql = sanitize_sql(sql, adapter)

                span = AppPerfRpm.tracer.start_span(name || 'SQL', tags: {
                  "component" => "ActiveRecord",
                  "span.kind" => "client",
                  "db.statement" => sanitized_sql,
                  "db.user" => connection_config.fetch(:username, 'unknown'),
                  "db.instance" => connection_config.fetch(:database),
                  "db.vendor" => adapter,
                  "db.type" => "sql"
                })
                AppPerfRpm::Utils.log_source_and_backtrace(span, :active_record)
              end
            end

            execute_without_trace(sql, name)
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
  end
end
