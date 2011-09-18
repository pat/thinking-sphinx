require 'spec_helper'

describe ThinkingSphinx::ActiveRecord::DatabaseAdapters::PostgreSQLAdapter do
  let(:adapter) {
    ThinkingSphinx::ActiveRecord::DatabaseAdapters::PostgreSQLAdapter.new(model)
  }
  let(:model)   { double('model') }

  describe '#cast_to_timestamp' do
    it "converts to unix timestamps" do
      adapter.cast_to_timestamp('created_at').
        should == 'cast(extract(epoch from created_at) as int)'
    end
  end

  describe '#concatenate' do
    it "concatenates with the given separator" do
      adapter.concatenate('foo, bar, baz', ',').
        should == "foo || ',' || bar || ',' || baz"
    end
  end

  describe '#convert_nulls' do
    it "translates arguments to a COALESCE SQL call" do
      adapter.convert_nulls('id', 5).should == 'COALESCE(id, 5)'
    end
  end

  describe '#group_concatenate' do
    it "group concatenates the clause with the given separator" do
      adapter.group_concatenate('foo', ',').
        should == "array_to_string(array_agg(foo), ',')"
    end
  end
end
