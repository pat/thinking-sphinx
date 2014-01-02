require 'spec_helper'

describe ThinkingSphinx::RealTime::Field do
  let(:field)  { ThinkingSphinx::RealTime::Field.new column }
  let(:column) { double('column', :__name => :created_at, :__stack => []) }

  describe '#column' do
    it 'returns the provided Column object' do
      field.column.should == column
    end

    it 'translates symbols to Column objects' do
      ThinkingSphinx::ActiveRecord::Column.should_receive(:new).with(:title).
        and_return(column)

      ThinkingSphinx::RealTime::Field.new :title
    end
  end

  describe '#name' do
    it "uses the provided option by default" do
      field = ThinkingSphinx::RealTime::Field.new column, :as => :foo
      field.name.should == 'foo'
    end

    it "falls back to the column's name" do
      field.name.should == 'created_at'
    end
  end

  describe '#translate' do
    let(:klass)  { Struct.new(:name, :parent) }
    let(:object) { klass.new 'the object name', parent }
    let(:parent) { klass.new 'the parent name', nil }

    it "returns the column's name if it's a string" do
      column.stub :__name => 'value'

      field.translate(object).should == 'value'
    end

    it "returns the column's name as a string if it's an integer" do
      column.stub :__name => 404

      field.translate(object).should == '404'
    end

    it "returns the object's method matching the column's name" do
      object.stub :created_at => 'a time'

      field.translate(object).should == 'a time'
    end

    it "uses the column's stack to navigate through the object tree" do
      column.stub :__name => :name, :__stack => [:parent]

      field.translate(object).should == 'the parent name'
    end

    it "returns a blank string if any element in the object tree is nil" do
      column.stub :__name => :name, :__stack => [:parent]
      object.parent = nil

      field.translate(object).should == ''
    end
  end
end
