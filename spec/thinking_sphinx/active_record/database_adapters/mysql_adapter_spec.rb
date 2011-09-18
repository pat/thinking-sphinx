require 'spec_helper'

describe ThinkingSphinx::ActiveRecord::DatabaseAdapters::MySQLAdapter do
  let(:adapter) {
    ThinkingSphinx::ActiveRecord::DatabaseAdapters::MySQLAdapter.new(model)
  }
  let(:model)   { double('model') }

  describe '#cast_to_timestamp' do
    it "converts to unix timestamps" do
      adapter.cast_to_timestamp('created_at').
        should == 'UNIX_TIMESTAMP(created_at)'
    end
  end

  describe '#convert_nulls' do
    it "translates arguments to an IFNULL SQL call" do
      adapter.convert_nulls('id', 5).should == 'IFNULL(id, 5)'
    end
  end

  describe '#group_concatenate' do
    it "group concatenates the clause with the given separator" do
      adapter.group_concatenate('foo', ',').
        should == "GROUP_CONCAT(foo SEPARATOR ',')"
    end
  end
end
