require 'spec_helper'

describe ThinkingSphinx::Context do
  let(:ts_context) { ThinkingSphinx::Context.new }

  describe '#prepare' do
    let(:config)           { ThinkingSphinx::Configuration.instance }
    let(:file_name)        { 'a.rb' }
    let(:model_name_lower) { 'a' }
    let(:class_name)       { 'A' }

    before :each do
      config.model_directories = ['']

      file_name.stub!(:gsub).and_return(model_name_lower)
      model_name_lower.stub!(:camelize).and_return(class_name)
      Dir.stub(:[]).and_return([file_name])
    end

    it "should load the files by guessing the file name" do
      class_name.should_receive(:constantize).and_return(true)

      ts_context.prepare
    end

    it "should not raise errors if the model name is nil" do
      file_name.stub!(:gsub).and_return(nil)

      lambda {
        ts_context.prepare
      }.should_not raise_error
    end

    it "should report name errors but not raise them" do
      class_name.stub(:constantize).and_raise(NameError)
      STDERR.stub!(:puts => '')
      STDERR.should_receive(:puts).with('Warning: Error loading a.rb:')

      lambda {
        ts_context.prepare
      }.should_not raise_error
    end

    it "should report load errors but not raise them" do
      class_name.stub(:constantize).and_raise(LoadError)
      STDERR.stub!(:puts => '')
      STDERR.should_receive(:puts).with('Warning: Error loading a.rb:')

      lambda {
        ts_context.prepare
      }.should_not raise_error
    end

    it "should catch database errors with a warning" do
      class_name.should_receive(:constantize).and_raise(Mysql2::Error)
      STDERR.stub!(:puts => '')
      STDERR.should_receive(:puts).with('Warning: Error loading a.rb:')

      lambda {
        ts_context.prepare
      }.should_not raise_error
    end unless RUBY_PLATFORM == 'java'

    it "should not load models if they're explicitly set in the configuration" do
      config.indexed_models = ['Alpha', 'Beta']
      ts_context.prepare

      ts_context.indexed_models.should == ['Alpha', 'Beta']
    end
  end

  describe '#define_indexes' do
    it "should call define_indexes on all known indexed models" do
      ts_context.stub!(:indexed_models => ['Alpha', 'Beta'])
      Alpha.should_receive(:define_indexes)
      Beta.should_receive(:define_indexes)

      ts_context.define_indexes
    end
  end

  describe '#add_indexed_model' do
    before :each do
      ts_context.indexed_models.clear
    end

    it "should add the model to the collection" do
      ts_context.add_indexed_model 'Alpha'

      ts_context.indexed_models.should == ['Alpha']
    end

    it "should not duplicate models in the collection" do
      ts_context.add_indexed_model 'Alpha'
      ts_context.add_indexed_model 'Alpha'

      ts_context.indexed_models.should == ['Alpha']
    end

    it "should keep the collection in alphabetical order" do
      ts_context.add_indexed_model 'Beta'
      ts_context.add_indexed_model 'Alpha'

      ts_context.indexed_models.should == ['Alpha', 'Beta']
    end

    it "should translate classes to their names" do
      ts_context.add_indexed_model Alpha

      ts_context.indexed_models.should == ['Alpha']
    end
  end

  describe '#superclass_indexed_models' do
    it "should return indexed model names" do
      ts_context.stub!(:indexed_models => ['Alpha', 'Beta'])

      ts_context.superclass_indexed_models.should == ['Alpha', 'Beta']
    end

    it "should not include classes which have indexed superclasses" do
      ts_context.stub!(:indexed_models => ['Parent', 'Person'])

      ts_context.superclass_indexed_models.should == ['Person']
    end
  end
end
