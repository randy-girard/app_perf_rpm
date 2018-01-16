logger = Logger.new(STDOUT)
logger.level = Logger::INFO

ActiveRecord::Base.logger = logger

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
end

class TestRecord < ApplicationRecord
end

begin
  TestRecord.count()
rescue ActiveRecord::StatementInvalid, ActiveRecord::NoDatabaseError
  ActiveRecord::Schema.define(version: 2018010101010101) do
    if ActiveRecord::Base.connection.table_exists? 'test_records'
      drop_table 'test_records'
    end

    create_table 'test_records', force: :cascade do |t|
      t.string   'name'
    end
  end
end

TestRecord.count()
