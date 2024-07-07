# frozen_string_literal: true

require 'spec_helper'

describe ThinkingSphinx::ActiveRecord::Interpreter do
  let(:instance) {
    ThinkingSphinx::ActiveRecord::Interpreter.new index, block
  }
  let(:model)   { double('model') }
  let(:index)   { double('index', :append_source => source, :options => {}) }
  let(:source)  {
    Struct.new(:attributes, :fields, :associations, :groupings, :conditions).
      new([], [], [], [], [])
  }
  let(:block)   { Proc.new { } }

  before :each do
    allow(ThinkingSphinx::ActiveRecord::SQLSource).to receive_messages(
      :new => source
    )

    allow(source).to receive_messages(
      :model => model, :add_attribute => nil, :add_field => nil
    )
  end

  describe '.translate!' do
    let(:instance) { double('interpreter', :translate! => true) }

    it "creates a new interpreter instance with the given block and index" do
      expect(ThinkingSphinx::ActiveRecord::Interpreter).to receive(:new).
        with(index, block).and_return(instance)

      ThinkingSphinx::ActiveRecord::Interpreter.translate! index, block
    end

    it "calls translate! on the instance" do
      allow(ThinkingSphinx::ActiveRecord::Interpreter).to receive_messages(:new => instance)
      expect(instance).to receive(:translate!)

      ThinkingSphinx::ActiveRecord::Interpreter.translate! index, block
    end
  end

  describe '#group_by' do
    it "adds a source to the index" do
      expect(index).to receive(:append_source).and_return(source)

      instance.group_by 'lat'
    end

    it "only adds a single source for the given context" do
      expect(index).to receive(:append_source).once.and_return(source)

      instance.group_by 'lat'
      instance.group_by 'lng'
    end

    it "appends a new grouping statement to the source" do
      instance.group_by 'lat'

      expect(source.groupings).to include('lat')
    end
  end

  describe '#has' do
    let(:column)    { double('column') }
    let(:attribute) { double('attribute') }

    before :each do
      allow(ThinkingSphinx::ActiveRecord::Attribute).to receive_messages :new => attribute
    end

    it "adds a source to the index" do
      expect(index).to receive(:append_source).and_return(source)

      instance.has column
    end

    it "only adds a single source for the given context" do
      expect(index).to receive(:append_source).once.and_return(source)

      instance.has column
      instance.has column
    end

    it "creates a new attribute with the provided column" do
      expect(ThinkingSphinx::ActiveRecord::Attribute).to receive(:new).
        with(model, column, {}).and_return(attribute)

      instance.has column
    end

    it "passes through options to the attribute" do
      expect(ThinkingSphinx::ActiveRecord::Attribute).to receive(:new).
        with(model, column, { :as => :other_name }).and_return(attribute)

      instance.has column, :as => :other_name
    end

    it "adds an attribute to the source" do
      expect(source).to receive(:add_attribute).with(attribute)

      instance.has column
    end

    it "adds multiple attributes when passed multiple columns" do
      expect(source).to receive(:add_attribute).with(attribute).twice

      instance.has column, column
    end
  end

  describe '#indexes' do
    let(:column) { double('column') }
    let(:field)  { double('field') }

    before :each do
      allow(ThinkingSphinx::ActiveRecord::Field).to receive_messages :new => field
    end

    it "adds a source to the index" do
      expect(index).to receive(:append_source).and_return(source)

      instance.indexes column
    end

    it "only adds a single source for the given context" do
      expect(index).to receive(:append_source).once.and_return(source)

      instance.indexes column
      instance.indexes column
    end

    it "creates a new field with the provided column" do
      expect(ThinkingSphinx::ActiveRecord::Field).to receive(:new).
        with(model, column, {}).and_return(field)

      instance.indexes column
    end

    it "passes through options to the field" do
      expect(ThinkingSphinx::ActiveRecord::Field).to receive(:new).
        with(model, column, { :as => :other_name }).and_return(field)

      instance.indexes column, :as => :other_name
    end

    it "adds a field to the source" do
      expect(source).to receive(:add_field).with(field)

      instance.indexes column
    end

    it "adds multiple fields when passed multiple columns" do
      expect(source).to receive(:add_field).with(field).twice

      instance.indexes column, column
    end
  end

  describe '#join' do
    let(:column)      { double('column') }
    let(:association) { double('association') }

    before :each do
      allow(ThinkingSphinx::ActiveRecord::Association).to receive_messages :new => association
    end

    it "adds a source to the index" do
      expect(index).to receive(:append_source).and_return(source)

      instance.join column
    end

    it "only adds a single source for the given context" do
      expect(index).to receive(:append_source).once.and_return(source)

      instance.join column
      instance.join column
    end

    it "creates a new association with the provided column" do
      expect(ThinkingSphinx::ActiveRecord::Association).to receive(:new).
        with(column).and_return(association)

      instance.join column
    end

    it "adds an association to the source" do
      instance.join column

      expect(source.associations).to include(association)
    end

    it "adds multiple fields when passed multiple columns" do
      instance.join column, column

      expect(source.associations.select { |saved_assoc|
        saved_assoc == association
      }.length).to eq(2)
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

  describe '#set_database' do
    before :each do
      allow(source).to receive_messages :set_database_settings => true

      stub_const 'ActiveRecord::Base',
        double(:configurations => {'other' => {'baz' => 'qux'}})
    end

    it "sends through a hash if provided" do
      expect(source).to receive(:set_database_settings).with({ :foo => :bar })

      instance.set_database :foo => :bar
    end

    it "finds the environment settings if given a string key" do
      expect(source).to receive(:set_database_settings).with({ :baz => 'qux' })

      instance.set_database 'other'
    end

    it "finds the environment settings if given a symbol key" do
      expect(source).to receive(:set_database_settings).with({ :baz => 'qux' })

      instance.set_database :other
    end
  end

  describe '#set_property' do
    before :each do
      allow(index.class).to receive_messages  :settings => [:morphology]
      allow(source.class).to receive_messages :settings => [:mysql_ssl_cert]
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

    context 'source settings' do
      before :each do
        allow(source).to receive_messages :mysql_ssl_cert= => true
      end

      it "adds a source to the index" do
        expect(index).to receive(:append_source).and_return(source)

        instance.set_property :mysql_ssl_cert => 'private.cert'
      end

      it "only adds a single source for the given context" do
        expect(index).to receive(:append_source).once.and_return(source)

        instance.set_property :mysql_ssl_cert => 'private.cert'
        instance.set_property :mysql_ssl_cert => 'private.cert'
      end

      it "sets the provided setting" do
        expect(source).to receive(:mysql_ssl_cert=).with('private.cert')

        instance.set_property :mysql_ssl_cert => 'private.cert'
      end
    end
  end

  describe '#translate!' do
    it "returns the block evaluated within the context of the interpreter" do
      block = Proc.new {
        __id__
      }

      interpreter = ThinkingSphinx::ActiveRecord::Interpreter.new index, block
      expect(interpreter.translate!).
        to eq(interpreter.__id__)
    end
  end

  describe '#where' do
    it "adds a source to the index" do
      expect(index).to receive(:append_source).and_return(source)

      instance.where 'id > 100'
    end

    it "only adds a single source for the given context" do
      expect(index).to receive(:append_source).once.and_return(source)

      instance.where 'id > 100'
      instance.where 'id < 150'
    end

    it "appends a new grouping statement to the source" do
      instance.where 'id > 100'

      expect(source.conditions).to include('id > 100')
    end
  end
end
