module AppPerfRpm
  module Utils
    REGEXP ||= Regexp.new('(\'[\s\S][^\']*\'|\d*\.\d+|\d+|NULL)')

    def sanitize_sql(sql, adapter)
      sql.gsub(REGEXP, '?')
    end

    def connection_config
      @connection_config ||= ::ActiveRecord::Base.connection_config
    end

    def format_redis(command)
      command.is_a?(Symbol) ? command.to_s.upcase : command.to_s
    rescue StandardError => e
      "?"
    end

    def format_redis_command(command)
      command.map { |x| format_redis(x) }.join(' ')
    end
  end
end
