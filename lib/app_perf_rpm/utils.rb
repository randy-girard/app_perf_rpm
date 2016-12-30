module AppPerfRpm
  module Utils
    def sanitize_sql(sql)
      regexp = Regexp.new('(\'[\s\S][^\']*\'|\d*\.\d+|\d+|NULL)', Regexp::IGNORECASE)
      sql.gsub(regexp, '?')
    end
  end
end
