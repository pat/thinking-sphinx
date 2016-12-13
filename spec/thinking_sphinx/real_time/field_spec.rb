require 'spec_helper'

describe ThinkingSphinx::RealTime::Field do
  let(:field)  { ThinkingSphinx::RealTime::Field.new column }
  let(:column) { double('column', :__name => :created_at, :__stack => []) }

  describe '#column' do
    it 'returns the provided Column object' do
      expect(field.column).to eq(column)
    end

    it 'translates symbols to Column objects' do
      expect(ThinkingSphinx::ActiveRecord::Column).to receive(:new).with(:title).
        and_return(column)

      ThinkingSphinx::RealTime::Field.new :title
    end
  end

  describe '#name' do
    it "uses the provided option by default" do
      field = ThinkingSphinx::RealTime::Field.new column, :as => :foo
      expect(field.name).to eq('foo')
    end

    it "falls back to the column's name" do
      expect(field.name).to eq('created_at')
    end
  end

  describe '#translate' do
    let(:klass)  { Struct.new(:name, :parent) }
    let(:object) { klass.new 'the object name', parent }
    let(:parent) { klass.new 'the parent name', nil }

    it "returns the column's name if it's a string" do
      allow(column).to receive_messages :__name => 'value'

      expect(field.translate(object)).to eq('value')
    end

    it "returns the column's name as a string if it's an integer" do
      allow(column).to receive_messages :__name => 404

      expect(field.translate(object)).to eq('404')
    end

    it "returns the object's method matching the column's name" do
      allow(object).to receive_messages :created_at => 'a time'

      expect(field.translate(object)).to eq('a time')
    end

    it "uses the column's stack to navigate through the object tree" do
      allow(column).to receive_messages :__name => :name, :__stack => [:parent]

      expect(field.translate(object)).to eq('the parent name')
    end

    it "returns a blank string if any element in the object tree is nil" do
      allow(column).to receive_messages :__name => :name, :__stack => [:parent]
      object.parent = nil

      expect(field.translate(object)).to eq('')
    end
  end
end
