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
              sanitized_sql = sanitize_sql(sql)

              opts = {
                :adapter => "mysql2",
                :sql => sanitized_sql,
                :name => name
              }

              opts.merge!(:backtrace => ::AppPerfRpm.clean_trace)

              AppPerfRpm::Tracer.trace('activerecord', opts || {}) do
                execute_without_trace(sql, name)
              end
            end
          end
        end
      end
    end
  end
end
