require 'spec_helper'

describe ThinkingSphinx::ActiveRecord::Interpreter do
  let(:model)   { double('model') }
  let(:index)   {
    double('index', :sources => sources, :model => model, :offset => 17)
  }
  let(:sources) { double('sources', :<< => source) }
  let(:source)  { double('source') }
  let(:block)   { Proc.new { } }

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

  describe '#indexes' do
    let(:instance) {
      ThinkingSphinx::ActiveRecord::Interpreter.new index, block
    }
    let(:column)   { double('column') }
    let(:fields)   { double('fields', :<< => field) }
    let(:field)    { double('field') }

    before :each do
      source.stub! :fields => fields

      ThinkingSphinx::ActiveRecord::SQLSource.stub! :new => source
      ThinkingSphinx::ActiveRecord::Field.stub! :new => field
    end

    it "adds a source to the index" do
      index.sources.should_receive(:<<).with(source)

      instance.indexes column
    end

    it "only adds a single source for the given context" do
      index.sources.should_receive(:<<).once

      instance.indexes column
      instance.indexes column
    end

    it "creates the source with the index's offset" do
      ThinkingSphinx::ActiveRecord::SQLSource.should_receive(:new).
        with(model, :offset => 17).and_return(source)

      instance.indexes column
    end

    it "creates a new field with the provided column" do
      ThinkingSphinx::ActiveRecord::Field.should_receive(:new).with(column).
        and_return(field)

      instance.indexes column
    end

    it "adds a field to the source" do
      source.fields.should_receive(:<<).with(field)

      instance.indexes column
    end

    it "adds multiple fields when passed multiple columns" do
      source.fields.should_receive(:<<).with(field).twice

      instance.indexes column, column
    end
  end

  describe '#method_missing' do
    let(:instance) {
      ThinkingSphinx::ActiveRecord::Interpreter.new index, block
    }
    let(:column)   { double('column') }

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

  describe '#translate!' do
    it "returns the block evaluated within the context of the interpreter" do
      block = Proc.new {
        self.class.name
      }

      interpreter = ThinkingSphinx::ActiveRecord::Interpreter.new index, block
      interpreter.translate!.
        should == 'ThinkingSphinx::ActiveRecord::Interpreter'
    end
  end
end
