# frozen_string_literal: true

require 'spec_helper'

describe ThinkingSphinx::RealTime::Interpreter do
  let(:instance) {
    ThinkingSphinx::RealTime::Interpreter.new index, block
  }
  let(:model)   { double('model') }
  let(:index)   { Struct.new(:attributes, :fields, :options).new([], [], {}) }
  let(:block)   { Proc.new { } }

  describe '.translate!' do
    let(:instance) { double('interpreter', :translate! => true) }

    it "creates a new interpreter instance with the given block and index" do
      expect(ThinkingSphinx::RealTime::Interpreter).to receive(:new).
        with(index, block).and_return(instance)

      ThinkingSphinx::RealTime::Interpreter.translate! index, block
    end

    it "calls translate! on the instance" do
      allow(ThinkingSphinx::RealTime::Interpreter).to receive_messages(:new => instance)
      expect(instance).to receive(:translate!)

      ThinkingSphinx::RealTime::Interpreter.translate! index, block
    end
  end

  describe '#has' do
    let(:column)    { double('column') }
    let(:attribute) { double('attribute') }

    before :each do
      allow(ThinkingSphinx::RealTime::Attribute).to receive_messages :new => attribute
    end

    it "creates a new attribute with the provided column" do
      expect(ThinkingSphinx::RealTime::Attribute).to receive(:new).
        with(column, {}).and_return(attribute)

      instance.has column
    end

    it "passes through options to the attribute" do
      expect(ThinkingSphinx::RealTime::Attribute).to receive(:new).
        with(column, :as => :other_name).and_return(attribute)

      instance.has column, :as => :other_name
    end

    it "adds an attribute to the index" do
      instance.has column

      expect(index.attributes).to include(attribute)
    end

    it "adds multiple attributes when passed multiple columns" do
      instance.has column, column

      expect(index.attributes.select { |saved_attribute|
        saved_attribute == attribute
      }.length).to eq(2)
    end
  end

  describe '#indexes' do
    let(:column) { double('column') }
    let(:field)  { double('field') }

    before :each do
      allow(ThinkingSphinx::RealTime::Field).to receive_messages :new => field
    end

    it "creates a new field with the provided column" do
      expect(ThinkingSphinx::RealTime::Field).to receive(:new).
        with(column, {}).and_return(field)

      instance.indexes column
    end

    it "passes through options to the field" do
      expect(ThinkingSphinx::RealTime::Field).to receive(:new).
        with(column, :as => :other_name).and_return(field)

      instance.indexes column, :as => :other_name
    end

    it "adds a field to the index" do
      instance.indexes column

      expect(index.fields).to include(field)
    end

    it "adds multiple fields when passed multiple columns" do
      instance.indexes column, column

      expect(index.fields.select { |saved_field|
        saved_field == field
      }.length).to eq(2)
    end

    context 'sortable' do
      let(:attribute) { double('attribute') }

      before :each do
        allow(ThinkingSphinx::RealTime::Attribute).to receive_messages :new => attribute

        allow(column).to receive_messages :__name => :col
      end

      it "adds the _sort suffix to the field's name" do
        expect(ThinkingSphinx::RealTime::Attribute).to receive(:new).
          with(column, :as => :col_sort, :type => :string).
          and_return(attribute)

        instance.indexes column, :sortable => true
      end

      it "respects given aliases" do
        expect(ThinkingSphinx::RealTime::Attribute).to receive(:new).
          with(column, :as => :other_sort, :type => :string).
          and_return(attribute)

        instance.indexes column, :sortable => true, :as => :other
      end

      it "respects symbols instead of columns" do
        expect(ThinkingSphinx::RealTime::Attribute).to receive(:new).
          with(:title, :as => :title_sort, :type => :string).
          and_return(attribute)

        instance.indexes :title, :sortable => true
      end

      it "adds an attribute to the index" do
        instance.indexes column, :sortable => true

        expect(index.attributes).to include(attribute)
      end
    end
  end

  describe '#method_missing' do
    let(:column) { double('column') }

    before :each do
      allow(ThinkingSphinx::ActiveRecord::Column).to receive_messages(:new => column)
    end

    it "returns a new column for the given method" do
      expect(instance.id).to eq(column)
    end

    it "should initialise the column with the method name and arguments" do
      expect(ThinkingSphinx::ActiveRecord::Column).to receive(:new).
        with(:users, :posts, :subject).and_return(column)

      instance.users(:posts, :subject)
    end
  end

  describe '#scope' do
    it "passes the scope block through to the index" do
      expect(index).to receive(:scope=).with(instance_of(Proc))

      instance.scope { :foo }
    end
  end

  describe '#set_property' do
    before :each do
      allow(index.class).to receive_messages :settings => [:morphology]
    end

    it 'saves other settings as index options' do
      instance.set_property :field_weights => {:name => 10}

      expect(index.options[:field_weights]).to eq({:name => 10})
    end

    context 'index settings' do
      it "sets the provided setting" do
        expect(index).to receive(:morphology=).with('stem_en')

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
      expect(interpreter.translate!).
        to eq(interpreter.__id__)
    end
  end
end
