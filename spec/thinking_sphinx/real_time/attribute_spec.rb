require 'spec_helper'

describe ThinkingSphinx::RealTime::Attribute do
  let(:attribute) { ThinkingSphinx::RealTime::Attribute.new column }
  let(:column)    { double('column', :__name => :created_at, :__stack => []) }

  describe '#name' do
    it "uses the provided option by default" do
      attribute = ThinkingSphinx::RealTime::Attribute.new column, :as => :foo
      expect(attribute.name).to eq('foo')
    end

    it "falls back to the column's name" do
      expect(attribute.name).to eq('created_at')
    end
  end

  describe '#translate' do
    let(:klass)  { Struct.new(:name, :parent) }
    let(:object) { klass.new 'the object name', parent }
    let(:parent) { klass.new 'the parent name', nil }

    it "returns the column's name if it's a string" do
      allow(column).to receive_messages :__name => 'value'

      expect(attribute.translate(object)).to eq('value')
    end

    it "returns the column's name if it's an integer" do
      allow(column).to receive_messages :__name => 404

      expect(attribute.translate(object)).to eq(404)
    end

    it "returns the object's method matching the column's name" do
      allow(object).to receive_messages :created_at => 'a time'

      expect(attribute.translate(object)).to eq('a time')
    end

    it "uses the column's stack to navigate through the object tree" do
      allow(column).to receive_messages :__name => :name, :__stack => [:parent]

      expect(attribute.translate(object)).to eq('the parent name')
    end

    it "returns zero if any element in the object tree is nil" do
      allow(column).to receive_messages :__name => :name, :__stack => [:parent]
      object.parent = nil

      expect(attribute.translate(object)).to be_zero
    end
  end

  describe '#type' do
    it "returns the given type option" do
      attribute = ThinkingSphinx::RealTime::Attribute.new column,
        :type => :string
      expect(attribute.type).to eq(:string)
    end
  end
end
