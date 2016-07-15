require 'spec_helper'

describe ThinkingSphinx::ActiveRecord::DatabaseAdapters::AbstractAdapter do
  let(:adapter)    {
    ThinkingSphinx::ActiveRecord::DatabaseAdapters::AbstractAdapter.new model
  }
  let(:model)      { double('model', :connection => connection) }
  let(:connection) { double('connection') }

  describe '#quote' do
    it "uses the model's connection to quote columns" do
      expect(connection).to receive(:quote_column_name).with('foo')

      adapter.quote 'foo'
    end

    it "returns the quoted value" do
      allow(connection).to receive_messages :quote_column_name => '"foo"'

      expect(adapter.quote('foo')).to eq('"foo"')
    end
  end

  describe '#quoted_table_name' do
    it "passes the method through to the model" do
      expect(model).to receive(:quoted_table_name).and_return('"articles"')

      expect(adapter.quoted_table_name).to eq('"articles"')
    end
  end
end
