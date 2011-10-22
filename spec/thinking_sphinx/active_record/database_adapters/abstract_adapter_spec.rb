require 'spec_helper'

describe ThinkingSphinx::ActiveRecord::DatabaseAdapters::AbstractAdapter do
  let(:adapter)    {
    ThinkingSphinx::ActiveRecord::DatabaseAdapters::AbstractAdapter.new model
  }
  let(:model)      { double('model', :connection => connection) }
  let(:connection) { double('connection') }

  describe '#quote' do
    it "uses the model's connection to quote columns" do
      connection.should_receive(:quote_column_name).with('foo')

      adapter.quote 'foo'
    end

    it "returns the quoted value" do
      connection.stub :quote_column_name => '"foo"'

      adapter.quote('foo').should == '"foo"'
    end
  end

  describe '#quoted_table_name' do
    it "passes the method through to the model" do
      model.should_receive(:quoted_table_name).and_return('"articles"')

      adapter.quoted_table_name.should == '"articles"'
    end
  end
end
