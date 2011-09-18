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

  describe '#convert_nulls' do
    it "translates arguments to a COALESCE SQL call" do
      adapter.convert_nulls('id', 5).should == 'COALESCE(id, 5)'
    end
  end
end
