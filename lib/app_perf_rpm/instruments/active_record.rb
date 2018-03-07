# frozen_string_literal: true

module AppPerfRpm
  module Instruments
    module ActiveRecord
      module Adapters
      end
    end
  end
end

if ::AppPerfRpm.config.instrumentation[:active_record][:enabled] &&
  defined?(::ActiveRecord)
  AppPerfRpm.logger.info "Initializing activerecord tracer."

  if defined?(::ActiveRecord::ConnectionAdapters::SQLite3Adapter)
    require 'app_perf_rpm/instruments/active_record/adapters/sqlite3'
    ::ActiveRecord::ConnectionAdapters::SQLite3Adapter.send(:include,
      ::AppPerfRpm::Instruments::ActiveRecord::Adapters::Sqlite3
    )
    ::ActiveRecord::ConnectionAdapters::SQLite3Adapter.class_eval do
      if Rails.version < "3.1"
        alias_method :exec_query_without_trace, :execute
        alias_method :execute, :exec_query_with_trace
      else
        alias_method :exec_query_without_trace, :exec_query
        alias_method :exec_query, :exec_query_with_trace

        alias_method :exec_delete_without_trace, :exec_delete
        alias_method :exec_delete, :exec_delete_with_trace
      end
    end
  end

  if defined?(::ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)
    require 'app_perf_rpm/instruments/active_record/adapters/postgresql'
    ::ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.send(:include,
      ::AppPerfRpm::Instruments::ActiveRecord::Adapters::Postgresql
    )

    ::ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.class_eval do
      if Rails.version < "3.1"
        alias_method :exec_query_without_trace, :execute
        alias_method :execute, :exec_query_with_trace
      else
        alias_method :exec_query_without_trace, :exec_query
        alias_method :exec_query, :exec_query_with_trace

        alias_method :exec_delete_without_trace, :exec_delete
        alias_method :exec_delete, :exec_delete_with_trace
      end
    end
  end

  if defined?(::ActiveRecord::ConnectionAdapters::Mysql2Adapter)
    require 'app_perf_rpm/instruments/active_record/adapters/mysql2'
    ::ActiveRecord::ConnectionAdapters::Mysql2Adapter.send(:include,
      ::AppPerfRpm::Instruments::ActiveRecord::Adapters::Mysql2
    )

    ::ActiveRecord::ConnectionAdapters::Mysql2Adapter.class_eval do
      alias_method :execute_without_trace, :execute
      alias_method :execute, :execute_with_trace
    end
  end
end
