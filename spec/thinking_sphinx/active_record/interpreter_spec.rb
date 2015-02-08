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
    ThinkingSphinx::ActiveRecord::SQLSource.stub! :new => source
    source.stub :model => model
  end

  describe '.translate!' do
    let(:instance) { double('interpreter', :translate! => true) }

    it "creates a new interpreter instance with the given block and index" do
      ThinkingSphinx::ActiveRecord::Interpreter.should_receive(:new).
        with(index, block).and_return(instance)

      ThinkingSphinx::ActiveRecord::Interpreter.translate! index, block
    end

    it "calls translate! on the instance" do
      ThinkingSphinx::ActiveRecord::Interpreter.stub!(:new => instance)
      instance.should_receive(:translate!)

      ThinkingSphinx::ActiveRecord::Interpreter.translate! index, block
    end
  end

  describe '#group_by' do
    it "adds a source to the index" do
      index.should_receive(:append_source).and_return(source)

      instance.group_by 'lat'
    end

    it "only adds a single source for the given context" do
      index.should_receive(:append_source).once.and_return(source)

      instance.group_by 'lat'
      instance.group_by 'lng'
    end

    it "appends a new grouping statement to the source" do
      instance.group_by 'lat'

      source.groupings.should include('lat')
    end
  end

  describe '#has' do
    let(:column)    { double('column') }
    let(:attribute) { double('attribute') }

    before :each do
      ThinkingSphinx::ActiveRecord::Attribute.stub! :new => attribute
    end

    it "adds a source to the index" do
      index.should_receive(:append_source).and_return(source)

      instance.has column
    end

    it "only adds a single source for the given context" do
      index.should_receive(:append_source).once.and_return(source)

      instance.has column
      instance.has column
    end

    it "creates a new attribute with the provided column" do
      ThinkingSphinx::ActiveRecord::Attribute.should_receive(:new).
        with(model, column, {}).and_return(attribute)

      instance.has column
    end

    it "passes through options to the attribute" do
      ThinkingSphinx::ActiveRecord::Attribute.should_receive(:new).
        with(model, column, :as => :other_name).and_return(attribute)

      instance.has column, :as => :other_name
    end

    it "adds an attribute to the source" do
      instance.has column

      source.attributes.should include(attribute)
    end

    it "adds multiple attributes when passed multiple columns" do
      instance.has column, column

      source.attributes.select { |saved_attribute|
        saved_attribute == attribute
      }.length.should == 2
    end
  end

  describe '#indexes' do
    let(:column) { double('column') }
    let(:field)  { double('field') }

    before :each do
      ThinkingSphinx::ActiveRecord::Field.stub! :new => field
    end

    it "adds a source to the index" do
      index.should_receive(:append_source).and_return(source)

      instance.indexes column
    end

    it "only adds a single source for the given context" do
      index.should_receive(:append_source).once.and_return(source)

      instance.indexes column
      instance.indexes column
    end

    it "creates a new field with the provided column" do
      ThinkingSphinx::ActiveRecord::Field.should_receive(:new).
        with(model, column, {}).and_return(field)

      instance.indexes column
    end

    it "passes through options to the field" do
      ThinkingSphinx::ActiveRecord::Field.should_receive(:new).
        with(model, column, :as => :other_name).and_return(field)

      instance.indexes column, :as => :other_name
    end

    it "adds a field to the source" do
      instance.indexes column

      source.fields.should include(field)
    end

    it "adds multiple fields when passed multiple columns" do
      instance.indexes column, column

      source.fields.select { |saved_field|
        saved_field == field
      }.length.should == 2
    end
  end

  describe '#join' do
    let(:column)      { double('column') }
    let(:association) { double('association') }

    before :each do
      ThinkingSphinx::ActiveRecord::Association.stub! :new => association
    end

    it "adds a source to the index" do
      index.should_receive(:append_source).and_return(source)

      instance.join column
    end

    it "only adds a single source for the given context" do
      index.should_receive(:append_source).once.and_return(source)

      instance.join column
      instance.join column
    end

    it "creates a new association with the provided column" do
      ThinkingSphinx::ActiveRecord::Association.should_receive(:new).
        with(column).and_return(association)

      instance.join column
    end

    it "adds an association to the source" do
      instance.join column

      source.associations.should include(association)
    end

    it "adds multiple fields when passed multiple columns" do
      instance.join column, column

      source.associations.select { |saved_assoc|
        saved_assoc == association
      }.length.should == 2
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

  describe '#set_database' do
    before :each do
      source.stub :set_database_settings => true

      stub_const 'ActiveRecord::Base',
        double(:configurations => {'other' => {'baz' => 'qux'}})
    end

    it "sends through a hash if provided" do
      source.should_receive(:set_database_settings).with(:foo => :bar)

      instance.set_database :foo => :bar
    end

    it "finds the environment settings if given a string key" do
      source.should_receive(:set_database_settings).with(:baz => 'qux')

      instance.set_database 'other'
    end

    it "finds the environment settings if given a symbol key" do
      source.should_receive(:set_database_settings).with(:baz => 'qux')

      instance.set_database :other
    end
  end

  describe '#set_property' do
    before :each do
      index.class.stub  :settings => [:morphology]
      source.class.stub :settings => [:mysql_ssl_cert]
    end

    it 'saves other settings as index options' do
      instance.set_property :field_weights => {:name => 10}

      index.options[:field_weights].should == {:name => 10}
    end

    context 'index settings' do
      it "sets the provided setting" do
        index.should_receive(:morphology=).with('stem_en')

        instance.set_property :morphology => 'stem_en'
      end
    end

    context 'source settings' do
      before :each do
        source.stub :mysql_ssl_cert= => true
      end

      it "adds a source to the index" do
        index.should_receive(:append_source).and_return(source)

        instance.set_property :mysql_ssl_cert => 'private.cert'
      end

      it "only adds a single source for the given context" do
        index.should_receive(:append_source).once.and_return(source)

        instance.set_property :mysql_ssl_cert => 'private.cert'
        instance.set_property :mysql_ssl_cert => 'private.cert'
      end

      it "sets the provided setting" do
        source.should_receive(:mysql_ssl_cert=).with('private.cert')

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
      interpreter.translate!.
        should == interpreter.__id__
    end
  end

  describe '#where' do
    it "adds a source to the index" do
      index.should_receive(:append_source).and_return(source)

      instance.where 'id > 100'
    end

    it "only adds a single source for the given context" do
      index.should_receive(:append_source).once.and_return(source)

      instance.where 'id > 100'
      instance.where 'id < 150'
    end

    it "appends a new grouping statement to the source" do
      instance.where 'id > 100'

      source.conditions.should include('id > 100')
    end
  end
end
