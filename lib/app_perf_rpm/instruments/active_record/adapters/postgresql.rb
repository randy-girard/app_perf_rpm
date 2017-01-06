module AppPerfRpm
  module Instruments
    module ActiveRecord
      module Adapters
        module Postgresql
          include AppPerfRpm::Utils

          def ignore_trace?(name)
            %w(SCHEMA EXPLAIN CACHE).include?(name.to_s) ||
              (name && name.to_sym == :skip_logging) ||
              name == 'ActiveRecord::SchemaMigration Load'
          end

          def exec_query_with_trace(sql, name = nil, binds = [])
            if ignore_trace?(name)
              exec_query_without_trace(sql, name, binds)
            else
              sanitized_sql = sanitize_sql(sql)

              opts = {
                :adapter => "postgresql",
                :query => sanitized_sql,
                :name => name
              }

              opts.merge!(:backtrace => ::AppPerfRpm.clean_trace)

              AppPerfRpm::Tracer.trace('activerecord', opts) do
                exec_query_without_trace(sql, name, binds)
              end
            end
          end

          def exec_delete_with_trace(sql, name = nil, binds = [])
            if ignore_trace?(name)
              exec_delete_without_trace(sql, name, binds)
            else
              sanitized_sql = sanitize_sql(sql)

              opts = {
                :adapter => "postgresql",
                :sql => sanitized_sql,
                :name => name
              }

              opts.merge!(:backtrace => ::AppPerfRpm.clean_trace)

              AppPerfRpm::Tracer.trace('activerecord', opts) do
                exec_delete_without_trace(sql, name, binds)
              end
            end
          end

          def exec_insert_with_trace(sql, name = nil, binds = [], *args)
            if ignore_trace?(name)
              exec_insert_without_trace(sql, name, binds, *args)
            else
              sanitized_sql = sanitize_sql(sql)

              opts = {
                :adapter => "postgresql",
                :sql => sanitized_sql,
                :name => name
              }

              opts.merge!(:backtrace => ::AppPerfRpm.clean_trace)
              AppPerfRpm::Tracer.trace('activerecord', opts) do
                exec_insert_without_trace(sql, name, binds, *args)
              end
            end
          end

          def begin_db_transaction_with_trace
            opts = {
              :adapter => "postgresql",
              :sql => "BEGIN"
            }
            AppPerfRpm::Tracer.trace('activerecord', opts) do
              begin_db_transaction_without_trace
            end
          end
        end
      end
    end
  end
end
