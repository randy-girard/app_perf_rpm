require 'spec_helper'
require 'support/rails'
require 'uri'

describe ActiveRecord do
  before do
    set_adapter_options
  end

  it "should collect span on find" do
    AppPerfRpm.without_tracing do
      @record = TestRecord.create(:name => "test")
    end

    AppPerfRpm::Instrumentation.load
    AppPerfRpm.tracing_on

    allow(AppPerfRpm::Tracer).to receive(:sampled?) { true }

    TestRecord.find(@record.id)

    if mysql2?
      expect(span_to_tag_hash).to eq([
        {"component"=>"ActiveRecord", "span.kind"=>"client", "db.statement"=>_sql(:select, "SELECT  `test_records`.* FROM `test_records` WHERE `test_records`.`id` = ? LIMIT ?")}.merge(@adapter_options),
      ])
    elsif postgresql?
      expect(span_to_tag_hash).to eq([
        {"component"=>"ActiveRecord", "span.kind"=>"client", "db.statement"=>_sql(:select, "SELECT  \"test_records\".* FROM \"test_records\" WHERE \"test_records\".\"id\" = $? LIMIT $?")}.merge(@adapter_options)
      ])
    elsif sqlite3?
      expect(span_to_tag_hash).to eq([
        {"component"=>"ActiveRecord", "span.kind"=>"client", "db.statement"=>_sql(:select, "SELECT  \"test_records\".* FROM \"test_records\" WHERE \"test_records\".\"id\" = ? LIMIT ?")}.merge(@adapter_options)
      ])
    end
  end

  it "should collect span on create" do
    AppPerfRpm::Instrumentation.load
    AppPerfRpm.tracing_on

    allow(AppPerfRpm::Tracer).to receive(:sampled?) { true }

    TestRecord.create(:name => "test")

    if mysql2?
      expect(span_to_tag_hash).to eq([
        {"component"=>"ActiveRecord", "span.kind"=>"client", "db.statement"=>"BEGIN"}.merge(@adapter_options),
        {"component"=>"ActiveRecord", "span.kind"=>"client", "db.statement"=>_sql(:insert, "INSERT INTO `test_records` (`name`) VALUES (?)")}.merge(@adapter_options),
        {"component"=>"ActiveRecord", "span.kind"=>"client", "db.statement"=>"COMMIT"}.merge(@adapter_options)
      ])
    elsif postgresql?
      expect(span_to_tag_hash).to eq([
        {"component"=>"ActiveRecord", "span.kind"=>"client", "db.statement"=>_sql(:insert, "INSERT INTO \"test_records\" (\"name\") VALUES ($?) RETURNING \"id\"")}.merge(@adapter_options)
      ])
    elsif sqlite3?
      expect(span_to_tag_hash.last).to eq(
        {"component"=>"ActiveRecord", "span.kind"=>"client", "db.statement"=>_sql(:insert, "INSERT INTO \"test_records\" (\"name\") VALUES (?)")}.merge(@adapter_options)
      )
    end
  end

  it "should collect span on destroy" do
    AppPerfRpm.without_tracing do
      @record = TestRecord.create(:name => "test")
    end

    AppPerfRpm::Instrumentation.load
    AppPerfRpm.tracing_on

    allow(AppPerfRpm::Tracer).to receive(:sampled?) { true }

    @record.destroy

    if mysql2?
      expect(span_to_tag_hash).to eq([
        {"component"=>"ActiveRecord", "span.kind"=>"client", "db.statement"=>"BEGIN"}.merge(@adapter_options),
        {"component"=>"ActiveRecord", "span.kind"=>"client", "db.statement"=>_sql(:delete, "DELETE FROM `test_records` WHERE `test_records`.`id` = ?")}.merge(@adapter_options),
        {"component"=>"ActiveRecord", "span.kind"=>"client", "db.statement"=>"COMMIT"}.merge(@adapter_options)
      ])
    elsif postgresql?
      expect(span_to_tag_hash).to eq([
        {"component"=>"ActiveRecord", "span.kind"=>"client", "db.statement"=>_sql(:delete, "DELETE FROM \"test_records\" WHERE \"test_records\".\"id\" = $?")}.merge(@adapter_options)
      ])
    elsif sqlite3?
      result = [
        {"component"=>"ActiveRecord", "span.kind"=>"client", "db.statement"=>_sql(:delete, "DELETE FROM \"test_records\" WHERE \"test_records\".\"id\" = ?")}.merge(@adapter_options)
      ]

      # TODO: Not sure why version 3.1+ issue multiple deletes.
      if Rails.version >= "3.1"
        result << {"component"=>"ActiveRecord", "span.kind"=>"client", "db.statement"=>_sql(:delete, "DELETE FROM \"test_records\" WHERE \"test_records\".\"id\" = ?")}.merge(@adapter_options)
      end

      expect(span_to_tag_hash).to eq(result)
    end
  end
end
