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
              if ignore_trace?(name)
                execute_without_trace(sql, name)
              else
                sanitized_sql = sanitize_sql(sql)

                opts = {
                  :adapter => "mysql2",
                  :query => sanitized_sql,
                  :name => name
                }

                opts[:backtrace] = ::AppPerfRpm::Backtrace.backtrace
                opts[:source] = ::AppPerfRpm::Backtrace.source_extract

                AppPerfRpm::Tracer.trace('activerecord', opts || {}) do
                  execute_without_trace(sql, name)
                end
              end
            else
              execute_without_trace(sql, name)
            end
          end
        end
      end
    end
  end
end
