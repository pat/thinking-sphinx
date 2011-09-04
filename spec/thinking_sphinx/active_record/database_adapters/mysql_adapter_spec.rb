require 'spec_helper'

describe ThinkingSphinx::ActiveRecord::DatabaseAdapters::MySQLAdapter do
  let(:adapter) {
    ThinkingSphinx::ActiveRecord::DatabaseAdapters::MySQLAdapter.new(model)
  }
  let(:model)   { double('model') }

  describe '#convert_nulls' do
    it "translates arguments to an IFNULL SQL call" do
      adapter.convert_nulls('id', 5).should == 'IFNULL(id, 5)'
    end
  end
end
