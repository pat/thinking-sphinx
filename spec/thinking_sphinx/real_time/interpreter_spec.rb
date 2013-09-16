require 'spec_helper'

describe ThinkingSphinx::RealTime::Interpreter do
  let(:instance) {
    ThinkingSphinx::RealTime::Interpreter.new index, block
  }
  let(:model)   { double('model') }
  let(:index)   { Struct.new(:attributes, :fields).new([], []) }
  let(:block)   { Proc.new { } }

  describe '.translate!' do
    let(:instance) { double('interpreter', :translate! => true) }

    it "creates a new interpreter instance with the given block and index" do
      ThinkingSphinx::RealTime::Interpreter.should_receive(:new).
        with(index, block).and_return(instance)

      ThinkingSphinx::RealTime::Interpreter.translate! index, block
    end

    it "calls translate! on the instance" do
      ThinkingSphinx::RealTime::Interpreter.stub!(:new => instance)
      instance.should_receive(:translate!)

      ThinkingSphinx::RealTime::Interpreter.translate! index, block
    end
  end

  describe '#has' do
    let(:column)    { double('column') }
    let(:attribute) { double('attribute') }

    before :each do
      ThinkingSphinx::RealTime::Attribute.stub! :new => attribute
    end

    it "creates a new attribute with the provided column" do
      ThinkingSphinx::RealTime::Attribute.should_receive(:new).
        with(column, {}).and_return(attribute)

      instance.has column
    end

    it "passes through options to the attribute" do
      ThinkingSphinx::RealTime::Attribute.should_receive(:new).
        with(column, :as => :other_name).and_return(attribute)

      instance.has column, :as => :other_name
    end

    it "adds an attribute to the index" do
      instance.has column

      index.attributes.should include(attribute)
    end

    it "adds multiple attributes when passed multiple columns" do
      instance.has column, column

      index.attributes.select { |saved_attribute|
        saved_attribute == attribute
      }.length.should == 2
    end
  end

  describe '#indexes' do
    let(:column) { double('column') }
    let(:field)  { double('field') }

    before :each do
      ThinkingSphinx::RealTime::Field.stub! :new => field
    end

    it "creates a new field with the provided column" do
      ThinkingSphinx::RealTime::Field.should_receive(:new).
        with(column, {}).and_return(field)

      instance.indexes column
    end

    it "passes through options to the field" do
      ThinkingSphinx::RealTime::Field.should_receive(:new).
        with(column, :as => :other_name).and_return(field)

      instance.indexes column, :as => :other_name
    end

    it "adds a field to the index" do
      instance.indexes column

      index.fields.should include(field)
    end

    it "adds multiple fields when passed multiple columns" do
      instance.indexes column, column

      index.fields.select { |saved_field|
        saved_field == field
      }.length.should == 2
    end

    context 'sortable' do
      let(:attribute) { double('attribute') }

      before :each do
        ThinkingSphinx::RealTime::Attribute.stub! :new => attribute

        column.stub :__name => :col
      end

      it "adds the _sort suffix to the field's name" do
        ThinkingSphinx::RealTime::Attribute.should_receive(:new).
          with(column, :as => :col_sort, :type => :string).
          and_return(attribute)

        instance.indexes column, :sortable => true
      end

      it "respects given aliases" do
        ThinkingSphinx::RealTime::Attribute.should_receive(:new).
          with(column, :as => :other_sort, :type => :string).
          and_return(attribute)

        instance.indexes column, :sortable => true, :as => :other
      end

      it "adds an attribute to the index" do
        instance.indexes column, :sortable => true

        index.attributes.should include(attribute)
      end
    end
  end

  describe '#method_missing' do
    let(:column) { double('column') }

    before :each do
      ThinkingSphinx::ActiveRecord::Column.stub!(:new => column)
    end

    it "returns a new column for the given method" do
      instance.id.should == column
    end

    it "should initialise the column with the method name and arguments" do
      ThinkingSphinx::ActiveRecord::Column.should_receive(:new).
        with(:users, :posts, :subject).and_return(column)

      instance.users(:posts, :subject)
    end
  end

  describe '#scope' do
    it "passes the scope block through to the index" do
      index.should_receive(:scope=).with(instance_of(Proc))

      instance.scope { :foo }
    end
  end

  describe '#set_property' do
    before :each do
      index.class.stub :settings => [:morphology]
    end

    context 'index settings' do
      it "sets the provided setting" do
        index.should_receive(:morphology=).with('stem_en')

        instance.set_property :morphology => 'stem_en'
      end
    end
  end

  describe '#translate!' do
    it "returns the block evaluated within the context of the interpreter" do
      block = Proc.new {
        __id__
      }

      interpreter = ThinkingSphinx::RealTime::Interpreter.new index, block
      interpreter.translate!.
        should == interpreter.__id__
    end
  end
end
