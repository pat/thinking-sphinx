require 'spec_helper'

describe ThinkingSphinx::RealTime::Attribute do
  let(:attribute) { ThinkingSphinx::RealTime::Attribute.new column }
  let(:column)    { double('column', :__name => :created_at, :__stack => []) }

  describe '#name' do
    it "uses the provided option by default" do
      attribute = ThinkingSphinx::RealTime::Attribute.new column, :as => :foo
      attribute.name.should == 'foo'
    end

    it "falls back to the column's name" do
      attribute.name.should == 'created_at'
    end
  end

  describe '#translate' do
    let(:klass)  { Struct.new(:name, :parent) }
    let(:object) { klass.new 'the object name', parent }
    let(:parent) { klass.new 'the parent name', nil }

    it "returns the column's name if it's a string" do
      column.stub :__name => 'value'

      attribute.translate(object).should == 'value'
    end

    it "returns the column's name if it's an integer" do
      column.stub :__name => 404

      attribute.translate(object).should == 404
    end

    it "returns the object's method matching the column's name" do
      object.stub :created_at => 'a time'

      attribute.translate(object).should == 'a time'
    end

    it "uses the column's stack to navigate through the object tree" do
      column.stub :__name => :name, :__stack => [:parent]

      attribute.translate(object).should == 'the parent name'
    end

    it "returns nil if any element in the object tree is nil" do
      column.stub :__name => :name, :__stack => [:parent]
      object.parent = nil

      attribute.translate(object).should be_nil
    end
  end

  describe '#type' do
    it "returns the given type option" do
      attribute = ThinkingSphinx::RealTime::Attribute.new column,
        :type => :string
      attribute.type.should == :string
    end
  end
end
