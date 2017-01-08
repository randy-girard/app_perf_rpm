module AppPerfRpm
  module Instruments
    module ActiveRecord
      module Adapters
        module Mysql2
          include AppPerfRpm::Utils

          def ignore_trace?(name)
            %w(SCHEMA EXPLAIN CACHE).include?(name.to_s) ||
              (name && name.to_sym == :skip_logging) ||
              name == 'ActiveRecord::SchemaMigration Load'
          end

          def execute_with_trace(sql, name = nil)
            if ignore_trace?(name)
              execute_without_trace(sql, name)
            else
              if ::AppPerfRpm.tracing?
                sanitized_sql = sanitize_sql(sql)

                opts = {
                  :adapter => "mysql2",
                  :query => sanitized_sql,
                  :name => name
                }

                opts.merge!(:backtrace => ::AppPerfRpm::Backtrace.backtrace)
                opts.merge!(:source => ::AppPerfRpm::Backtrace.source_extract)

                AppPerfRpm::Tracer.trace('activerecord', opts || {}) do
                  execute_without_trace(sql, name)
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
end
