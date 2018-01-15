require 'spec_helper'
require 'support/rails'
require 'uri'

describe ActiveRecord do
  before do
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

  def operation_name
    Rails.version < "3.1" ? "AREL" : "SQL"
  end

  def _sql(method, sql)
    sql

    # Postgresql is the only adapter that uses returning.
    sql = sql.gsub(" RETURNING \"id\"", "") unless postgresql?

    sql = sql.gsub(/LIMIT \$\?/, "LIMIT ?")

    # Current obfuscater on postgres throws in an extra $
    if (postgresql? && Rails.version >= "3.1")
      sql = sql.gsub(/\?/, "$?")
    end

    # Mysql uses single ticks around fields, so modify the
    # expected value so that is matches the actual value.
    sql = sql.gsub("\"", '`') if mysql2?

    # There appears to be a bug in rails 4.1, that puts an extra
    # space before the where clause on selects and inserts.
    if (Rails.version >= "3.1" && Rails.version < "4.2" && method != :delete)
      sql = sql.gsub(" WHERE", "  WHERE")
    end

    sql
  end

  def allowed_queries
    span = double("Span (BEGIN)")
    allow(span).to receive(:log).with(event: "backtrace", stack: anything)
    allow(span).to receive(:log).with(event: "source", stack: anything)
    allow(span).to receive(:finish)
    allow(AppPerfRpm.tracer).to receive(:start_span).with("SQL", tags: {
      "component" => "ActiveRecord",
      "span.kind" => "client",
      "db.statement" => "BEGIN"
    }.merge(@adapter_options)) { span }

    span = double("Span (ROLLBACK)")
    allow(span).to receive(:log).with(event: "backtrace", stack: anything)
    allow(span).to receive(:log).with(event: "source", stack: anything)
    allow(span).to receive(:finish)
    allow(AppPerfRpm.tracer).to receive(:start_span).with("SQL", tags: {
      "component" => "ActiveRecord",
      "span.kind" => "client",
      "db.statement" => "ROLLBACK"
    }.merge(@adapter_options)) { span }

    span = double("Span (COMMIT)")
    allow(span).to receive(:log).with(event: "backtrace", stack: anything)
    allow(span).to receive(:log).with(event: "source", stack: anything)
    allow(span).to receive(:finish)
    allow(AppPerfRpm.tracer).to receive(:start_span).with("SQL", tags: {
      "component" => "ActiveRecord",
      "span.kind" => "client",
      "db.statement" => "COMMIT"
    }.merge(@adapter_options)) { span }

    span = double("Span (SQLITE_MASTER)")
    allow(span).to receive(:log).with(event: "backtrace", stack: anything)
    allow(span).to receive(:log).with(event: "source", stack: anything)
    allow(span).to receive(:finish)
    allow(AppPerfRpm.tracer).to receive(:start_span).with("SQL", tags: {
      "component" => "ActiveRecord",
      "span.kind" => "client",
      "db.statement" => "          SELECT name\n          FROM sqlite_master\n          WHERE type = ? AND NOT name = ?\n"
    }.merge(@adapter_options)) { span }
  end

  it "should collect span on find" do
    AppPerfRpm.without_tracing do
      @record = TestRecord.create(:name => "test")
    end

    AppPerfRpm::Instrumentation.load
    AppPerfRpm.tracing_on

    allow(AppPerfRpm::Tracer).to receive(:sampled?) { true }

    span = double("Span")
    expect(span).to receive(:log).with(event: "backtrace", stack: anything)
    expect(span).to receive(:log).with(event: "source", stack: anything)
    expect(span).to receive(:finish)
    expect(AppPerfRpm.tracer).to receive(:start_span).with("TestRecord Load", tags: {
      "component" => "ActiveRecord",
      "span.kind" => "client",
      "db.statement" => _sql(:select, "SELECT  \"test_records\".* FROM \"test_records\" WHERE \"test_records\".\"id\" = ? LIMIT ?")
    }.merge(@adapter_options)) { span }

    TestRecord.find(@record.id)
  end

  it "should collect span on create" do
    AppPerfRpm::Instrumentation.load
    AppPerfRpm.tracing_on

    allow(AppPerfRpm::Tracer).to receive(:sampled?) { true }

    allowed_queries

    span = double("Span")
    expect(span).to receive(:log).with(event: "backtrace", stack: anything)
    expect(span).to receive(:log).with(event: "source", stack: anything)
    expect(span).to receive(:finish)
    expect(AppPerfRpm.tracer).to receive(:start_span).with(operation_name, tags: {
      "component" => "ActiveRecord",
      "span.kind" => "client",
      "db.statement" => _sql(:insert, "INSERT INTO \"test_records\" (\"name\") VALUES (?) RETURNING \"id\"")
    }.merge(@adapter_options)) { span }

    TestRecord.create(:name => "test")
  end

  it "should collect span on destroy" do
    AppPerfRpm.without_tracing do
      @record = TestRecord.create(:name => "test")
    end

    AppPerfRpm::Instrumentation.load
    AppPerfRpm.tracing_on

    allow(AppPerfRpm::Tracer).to receive(:sampled?) { true }

    allowed_queries

    # The allows are hacks right now since for some reason sqlite3 wants
    # to expect 2, instead of 1.
    span = double("Span")
    allow(span).to receive(:log).with(event: "backtrace", stack: anything)
    allow(span).to receive(:log).with(event: "source", stack: anything)
    allow(span).to receive(:finish)
    allow(AppPerfRpm.tracer).to receive(:start_span).with(operation_name, tags: {
      "component" => "ActiveRecord",
      "span.kind" => "client",
      "db.statement" => _sql(:delete, "DELETE FROM \"test_records\" WHERE \"test_records\".\"id\" = ?")
    }.merge(@adapter_options)) { span }

    @record.destroy
  end
end
