module AppPerfRpm
  module Utils
    REGEXP ||= Regexp.new('(\'[\s\S][^\']*\'|\d*\.\d+|\d+|NULL)')

    def sanitize_sql(sql, adapter)
      sql.gsub(REGEXP, '?')
    end

    def connection_config
      @connection_config ||= if ::ActiveRecord::VERSION::MAJOR == 2
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
  end
end
