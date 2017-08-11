module AppPerfRpm
  module Utils
    REGEXP ||= Regexp.new('(\'[\s\S][^\']*\'|\d*\.\d+|\d+|NULL)')

    def sanitize_sql(sql, adapter)
      sql.gsub(REGEXP, '?')
    end
  end
end
