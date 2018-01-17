if defined?(ACTIVERECORD_IMPORT_LOADED) && ACTIVERECORD_IMPORT_LOADED
  require 'spec_helper'
  require 'support/rails'
  require 'uri'

  describe "ActiveRecordImport" do
    before do
      set_adapter_options
    end

    it "should collect span on import" do
      AppPerfRpm::Instrumentation.load
      AppPerfRpm.tracing_on

      allow(AppPerfRpm::Tracer).to receive(:sampled?) { true }

      values = "nextval(?),?"
      component = "ActiveRecordImport"
      if sqlite3?
        component = "ActiveRecord"
        operation = "TestRecord Create Many Without Validations Or Callbacks"
        values = "?,?"
      elsif postgresql?
        operation = "ActiveRecord::ConnectionAdapters::PostgreSQLAdapter"
      else
        component = "ActiveRecord"
        operation = "SQL"
      end

      record1 = TestRecord.new(:name => "value")
      record2 = TestRecord.new(:name => "value 2")
      TestRecord.import([record1, record2])

      if mysql2?
        expect(span_to_tag_hash).to eq([
          {"component"=>"ActiveRecord", "span.kind"=>"client", "db.statement"=>"SHOW VARIABLES like ?;"}.merge(@adapter_options),
          {"component"=>"ActiveRecord", "span.kind"=>"client", "db.statement"=>"INSERT INTO `test_records` (`id`,`name`) VALUES (?,?),(?,?)"}.merge(@adapter_options)
        ])
      elsif postgresql?
        expect(span_to_tag_hash).to eq([
          {"component"=>"ActiveRecordImport", "span.kind"=>"client", "db.statement"=>"INSERT INTO \"test_records\" (\"id\",\"name\") VALUES (nextval(?),?),(nextval(?),?) RETURNING \"id\""}.merge(@adapter_options),
        ])
      elsif sqlite3?
        expect(span_to_tag_hash).to eq([
          {"component"=>"ActiveRecord", "span.kind"=>"client", "db.statement"=>"select sqlite_version(*)"}.merge(@adapter_options),
          {"component"=>"ActiveRecord", "span.kind"=>"client", "db.statement"=>"INSERT INTO \"test_records\" (\"id\",\"name\") VALUES (?,?),(?,?)"}.merge(@adapter_options)
        ])
      end
    end
  end
end
