# frozen_string_literal: true

require 'spec_helper'

describe ThinkingSphinx::ActiveRecord::DatabaseAdapters::MySQLAdapter do
  let(:adapter) {
    ThinkingSphinx::ActiveRecord::DatabaseAdapters::MySQLAdapter.new(model)
  }
  let(:model)   { double('model') }

  it "returns 1 for true" do
    expect(adapter.boolean_value(true)).to eq(1)
  end

  it "returns 0 for false" do
    expect(adapter.boolean_value(false)).to eq(0)
  end

  describe '#cast_to_string' do
    it "casts the clause to characters" do
      expect(adapter.cast_to_string('foo')).to eq("CAST(foo AS char)")
    end
  end

  describe '#cast_to_timestamp' do
    it "converts to unix timestamps" do
      expect(adapter.cast_to_timestamp('created_at')).
        to eq('UNIX_TIMESTAMP(created_at)')
    end
  end

  describe '#concatenate' do
    it "concatenates with the given separator" do
      expect(adapter.concatenate('foo, bar, baz', ',')).
        to eq("CONCAT_WS(',', foo, bar, baz)")
    end
  end

  describe '#convert_nulls' do
    it "translates arguments to an IFNULL SQL call" do
      expect(adapter.convert_nulls('id', 5)).to eq('IFNULL(id, 5)')
    end
  end

  describe '#convert_blank' do
    it "translates arguments to a COALESCE NULLIF SQL call" do
      expect(adapter.convert_blank('id', 5)).to eq("COALESCE(NULLIF(id, ''), 5)")
    end
  end

  describe '#group_concatenate' do
    it "group concatenates the clause with the given separator" do
      expect(adapter.group_concatenate('foo', ',')).
        to eq("GROUP_CONCAT(DISTINCT foo SEPARATOR ',')")
    end
  end

  describe '#utf8_query_pre' do
    it "defaults to using utf8" do
      expect(adapter.utf8_query_pre).to eq(["SET NAMES utf8"])
    end

    it "allows custom values" do
      ThinkingSphinx::Configuration.instance.settings['mysql_encoding'] =
        'utf8mb4'

      expect(adapter.utf8_query_pre).to eq(["SET NAMES utf8mb4"])
    end
  end
end
