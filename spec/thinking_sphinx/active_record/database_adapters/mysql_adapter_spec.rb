require 'spec_helper'

describe ThinkingSphinx::ActiveRecord::DatabaseAdapters::MySQLAdapter do
  let(:adapter) {
    ThinkingSphinx::ActiveRecord::DatabaseAdapters::MySQLAdapter.new(model)
  }
  let(:model)   { double('model') }

  it "returns 1 for true" do
    adapter.boolean_value(true).should == 1
  end

  it "returns 0 for false" do
    adapter.boolean_value(false).should == 0
  end

  describe '#cast_to_string' do
    it "casts the clause to characters" do
      adapter.cast_to_string('foo').should == "CAST(foo AS char)"
    end
  end

  describe '#cast_to_timestamp' do
    it "converts to unix timestamps" do
      adapter.cast_to_timestamp('created_at').
        should == 'UNIX_TIMESTAMP(created_at)'
    end
  end

  describe '#concatenate' do
    it "concatenates with the given separator" do
      adapter.concatenate('foo, bar, baz', ',').
        should == "CONCAT_WS(',', foo, bar, baz)"
    end
  end

  describe '#convert_nulls' do
    it "translates arguments to an IFNULL SQL call" do
      adapter.convert_nulls('id', 5).should == 'IFNULL(id, 5)'
    end
  end

  describe '#convert_nulls_or_blank' do
    it "translates arguments to a COALESCE NULLIF SQL call" do
      adapter.convert_nulls_or_blank('id', 5).should == "COALESCE(NULLIF(id, ''), 5)"
    end
  end


  describe '#group_concatenate' do
    it "group concatenates the clause with the given separator" do
      adapter.group_concatenate('foo', ',').
        should == "GROUP_CONCAT(DISTINCT foo SEPARATOR ',')"
    end
  end
end
