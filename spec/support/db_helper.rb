begin
  require 'pg'
  ENV['DATABASE_URL'] = 'postgresql://127.0.0.1:5432/postgres'
rescue LoadError
end

begin
  require 'mysql2'
  ENV['DATABASE_URL'] = 'mysql2://127.0.0.1:3306/mysql'
rescue LoadError
end

begin
  require 'sqlite3'
  if Rails.version >= "4.0"
    ENV['DATABASE_URL'] = "sqlite3:///#{Dir.tmpdir}/app_perf_rpm_db.sqlite3"
  end
rescue LoadError
end
