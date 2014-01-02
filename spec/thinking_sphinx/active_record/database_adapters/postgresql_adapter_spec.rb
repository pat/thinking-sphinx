require 'spec_helper'

describe ThinkingSphinx::ActiveRecord::DatabaseAdapters::PostgreSQLAdapter do
  let(:adapter) {
    ThinkingSphinx::ActiveRecord::DatabaseAdapters::PostgreSQLAdapter.new(model)
  }
  let(:model)   { double('model') }

  describe '#boolean_value' do
    it "returns 'TRUE' for true" do
      adapter.boolean_value(true).should == 'TRUE'
    end

    it "returns 'FALSE' for false" do
      adapter.boolean_value(false).should == 'FALSE'
    end
  end

  describe '#cast_to_string' do
    it "casts the clause to characters" do
      adapter.cast_to_string('foo').should == 'foo::varchar'
    end
  end

  describe '#cast_to_timestamp' do
    it "converts to int unix timestamps" do
      adapter.cast_to_timestamp('created_at').
        should == 'extract(epoch from created_at)::int'
    end

    it "converts to bigint unix timestamps" do
      ThinkingSphinx::Configuration.instance.settings['64bit_timestamps'] = true

      adapter.cast_to_timestamp('created_at').
        should == 'extract(epoch from created_at)::bigint'
    end
  end

  describe '#concatenate' do
    it "concatenates with the given separator" do
      adapter.concatenate('foo, bar, baz', ',').
        should == "COALESCE(foo, '') || ',' || COALESCE(bar, '') || ',' || COALESCE(baz, '')"
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
        should == "array_to_string(array_agg(DISTINCT foo), ',')"
    end
  end
end
