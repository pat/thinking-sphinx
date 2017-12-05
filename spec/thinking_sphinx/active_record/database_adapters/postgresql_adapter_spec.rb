# frozen_string_literal: true

require 'spec_helper'

describe ThinkingSphinx::ActiveRecord::DatabaseAdapters::PostgreSQLAdapter do
  let(:adapter) {
    ThinkingSphinx::ActiveRecord::DatabaseAdapters::PostgreSQLAdapter.new(model)
  }
  let(:model)   { double('model') }

  describe '#boolean_value' do
    it "returns 'TRUE' for true" do
      expect(adapter.boolean_value(true)).to eq('TRUE')
    end

    it "returns 'FALSE' for false" do
      expect(adapter.boolean_value(false)).to eq('FALSE')
    end
  end

  describe '#cast_to_string' do
    it "casts the clause to characters" do
      expect(adapter.cast_to_string('foo')).to eq('foo::varchar')
    end
  end

  describe '#cast_to_timestamp' do
    it "converts to int unix timestamps" do
      expect(adapter.cast_to_timestamp('created_at')).
        to eq('extract(epoch from created_at)::int')
    end

    it "converts to bigint unix timestamps" do
      ThinkingSphinx::Configuration.instance.settings['64bit_timestamps'] = true

      expect(adapter.cast_to_timestamp('created_at')).
        to eq('extract(epoch from created_at)::bigint')
    end
  end

  describe '#concatenate' do
    it "concatenates with the given separator" do
      expect(adapter.concatenate('foo, bar, baz', ',')).
        to eq("COALESCE(foo, '') || ',' || COALESCE(bar, '') || ',' || COALESCE(baz, '')")
    end
  end

  describe '#convert_nulls' do
    it "translates arguments to a COALESCE SQL call" do
      expect(adapter.convert_nulls('id', 5)).to eq('COALESCE(id, 5)')
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
        to eq("array_to_string(array_agg(DISTINCT foo), ',')")
    end
  end
end
