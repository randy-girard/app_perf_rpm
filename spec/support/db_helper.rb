begin
  require 'activerecord-import'
  ACTIVERECORD_IMPORT_LOADED = true
rescue LoadError
end

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
  require 'tmpdir'
  dir = Rails.version >= "4.1" ? "#{Dir.tmpdir}/" : "///#{Dir.tmpdir}/"
  if Rails.version >= "4.0"
    ENV['DATABASE_URL'] = "sqlite3:#{dir}app_perf_rpm_db.sqlite3"
  end
rescue LoadError
end

def set_adapter_options
  database_url = ENV["DATABASE_URL"]
  config = ActiveRecord::Base.connection.instance_variable_get(:@config)

  if (database_url.blank? && config.blank?) || database_url.to_s.match(":memory:")
    database = ":memory:"
    adapter = "sqlite3"
  elsif database_url
    uri = URI.parse(database_url)
    adapter = uri.scheme
    database = uri.path

    # For some reason, Rails below 4.2 append an extra slash to
    # the sqlite tmp dir.
    if adapter == "sqlite3" && Rails.version < "4.2" && database.match(/^\/\//)
      database = database.gsub(/^\/\//, "/")
    elsif adapter != "sqlite3"
      database = database.split("/").last
    end
  else
    adapter = config[:adapter]
    database = config[:database]
  end

  @adapter_options = {
    "db.user" => "unknown",
    "db.instance" => database,
    "db.vendor" => adapter,
    "db.type" => "sql"
  }
end

def mysql2?
  @adapter_options["db.vendor"] == "mysql2"
end

def postgresql?
  @adapter_options["db.vendor"] == "postgresql"
end

def sqlite3?
  @adapter_options["db.vendor"] == "sqlite3"
end

def operation_name
  Rails.version < "3.1" ? "AREL" : "SQL"
end

def _sql(method, sql, check_obfuscator = true)
  sql

  # There appears to be a bug in rails 4.1, that puts an extra
  # space before the where clause on selects and inserts.
  if (Rails.version >= "3.1" && Rails.version < "4.2" && method != :delete)
    sql = sql.gsub(" WHERE", "  WHERE")
  end

  sql
end
