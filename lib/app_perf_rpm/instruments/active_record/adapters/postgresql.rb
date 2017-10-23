module AppPerfRpm
  module Instruments
    module ActiveRecord
      module Adapters
        module Postgresql
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

          def exec_query_with_trace(sql, name = nil, binds = [], opts = {})
            if ::AppPerfRpm::Tracer.tracing?
              if ignore_trace?(name)
                exec_query_without_trace(sql, name, binds, opts)
              else
                sanitized_sql = sanitize_sql(sql, :postgres)

                AppPerfRpm::Tracer.trace('activerecord') do |span|
                  span.options = {
                    "adapter" => "postgresql",
                    "query" => sanitized_sql,
                    "name" => name
                  }
                  exec_query_without_trace(sql, name, binds, opts)
                end
              end
            else
              exec_query_without_trace(sql, name, binds, *args)
            end
          end

          def exec_delete_with_trace(sql, name = nil, binds = [])
            if ::AppPerfRpm::Tracer.tracing?
              if ignore_trace?(name)
                exec_delete_without_trace(sql, name, binds)
              else
                sanitized_sql = sanitize_sql(sql)

                AppPerfRpm::Tracer.trace('activerecord') do |span|
                  span.options = {
                    "adapter" => "postgresql",
                    "query" => sanitized_sql,
                    "name" => name
                  }
                  exec_delete_without_trace(sql, name, binds)
                end
              end
            else
              exec_delete_without_trace(sql, name, binds)
            end
          end

          def exec_insert_with_trace(sql, name = nil, binds = [], *args)
            if ::AppPerfRpm::Tracer.tracing?
              if ignore_trace?(name)
                exec_insert_without_trace(sql, name, binds, *args)
              else
                sanitized_sql = sanitize_sql(sql, :postgres)

                AppPerfRpm::Tracer.trace('activerecord') do |span|
                  span.options = {
                    "adapter" => "postgresql",
                    "query" => sanitized_sql,
                    "name" => name
                  }

                  exec_insert_without_trace(sql, name, binds, *args)
                end
              end
            else
              exec_insert_without_trace(sql, name, binds, *args)
            end
          end

          def begin_db_transaction_with_trace
            if ::AppPerfRpm::Tracer.tracing?
              AppPerfRpm::Tracer.trace('activerecord') do |span|
                span.options = {
                  "adapter" => "postgresql",
                  "query" => "BEGIN"
                }

                begin_db_transaction_without_trace
              end
            else
              begin_db_transaction_without_trace
            end
          end
        end
      end
    end
  end
end
