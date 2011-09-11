require 'spec_helper'

describe ThinkingSphinx::ActiveRecord::DatabaseAdapters::PostgreSQLAdapter do
  let(:adapter) {
    ThinkingSphinx::ActiveRecord::DatabaseAdapters::PostgreSQLAdapter.new(model)
  }
  let(:model)   { double('model') }

  describe '#convert_nulls' do
    it "translates arguments to a COALESCE SQL call" do
      adapter.convert_nulls('id', 5).should == 'COALESCE(id, 5)'
    end
  end
end
