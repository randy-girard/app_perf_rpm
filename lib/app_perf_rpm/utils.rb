# frozen_string_literal: true

module AppPerfRpm
  module Utils
    REGEXP ||= Regexp.new('(\'[\s\S][^\']*\'|\d*\.\d+|\d+|NULL)')

    def sanitize_sql(sql, adapter)
      sql.gsub(REGEXP, '?')
    end

    def connection_config
      @connection_config ||= if ::ActiveRecord::VERSION::MAJOR == 2 || (::ActiveRecord::VERSION::MAJOR == 3 && ::ActiveRecord::VERSION::MINOR < 1)
                               ActiveRecord::Base.connection.instance_variable_get(:@config)
                             else
                               ::ActiveRecord::Base.connection_config
                             end
    end

    def format_redis(command)
      command.is_a?(Symbol) ? command.to_s.upcase : command.to_s
    rescue StandardError => e
      "?"
    end

    def format_redis_command(command)
      command.map { |x| format_redis(x) }.join(' ')
    end

    def self.log_source_and_backtrace(span, instrument)
      config = ::AppPerfRpm.config.instrumentation[instrument] || {}
      if kind = config[:backtrace]
        backtrace = AppPerfRpm::Backtrace.backtrace(kind: kind)
        if backtrace.length > 0
          span.log(event: "backtrace", stack: backtrace)
        end
      end
      if config[:source]
        source = AppPerfRpm::Backtrace.source_extract
        if source.length > 0
          span.log(event: "source", stack: source)
        end
      end
    end
  end
end
