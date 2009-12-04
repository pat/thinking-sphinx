require 'spec/spec_helper'

describe ThinkingSphinx::Context do
  before :each do
    @context = ThinkingSphinx::Context.new
  end
  
  describe '#prepare' do
    before :each do
      @config = ThinkingSphinx::Configuration.instance
      @config.model_directories = ['']

      @file_name        = 'a.rb'
      @model_name_lower = 'a'
      @class_name       = 'A'

      @file_name.stub!(:gsub).and_return(@model_name_lower)
      @model_name_lower.stub!(:camelize).and_return(@class_name)
      Dir.stub(:[]).and_return([@file_name])
    end

    it "should load the files by guessing the file name" do
      @class_name.should_receive(:constantize).and_return(true)

      @context.prepare
    end

    it "should not raise errors if the model name is nil" do
      @file_name.stub!(:gsub).and_return(nil)

      lambda {
        @context.prepare
      }.should_not raise_error
    end

    it "should not raise errors if the file name does not represent a class name" do
      @class_name.should_receive(:constantize).and_raise(NameError)

      lambda {
        @context.prepare
      }.should_not raise_error
    end

    it "should retry if the first pass fails and contains a directory" do
      @model_name_lower.stub!(:gsub!).and_return(true, nil)
      @class_name.stub(:constantize).and_raise(LoadError)
      @model_name_lower.should_receive(:camelize).twice

      lambda {
        @context.prepare
      }.should_not raise_error
    end

    it "should catch database errors with a warning" do
      @class_name.should_receive(:constantize).and_raise(Mysql::Error)
      STDERR.should_receive(:puts).with('Warning: Error loading a.rb')

      lambda {
        @context.prepare
      }.should_not raise_error
    end
  end
  
  describe '#define_indexes' do
    it "should call process_indexes on all known indexed models" do
      @context.stub!(:indexed_models => ['Alpha', 'Beta'])
      Alpha.should_receive(:process_indexes)
      Beta.should_receive(:process_indexes)
      
      @context.define_indexes
    end
  end
  
  describe '#add_indexed_model' do
    before :each do
      @context.indexed_models.clear
    end
    
    it "should add the model to the collection" do
      @context.add_indexed_model 'Alpha'
      
      @context.indexed_models.should == ['Alpha']
    end
    
    it "should not duplicate models in the collection" do
      @context.add_indexed_model 'Alpha'
      @context.add_indexed_model 'Alpha'
      
      @context.indexed_models.should == ['Alpha']
    end
    
    it "should keep the collection in alphabetical order" do
      @context.add_indexed_model 'Beta'
      @context.add_indexed_model 'Alpha'
      
      @context.indexed_models.should == ['Alpha', 'Beta']
    end
    
    it "should translate classes to their names" do
      @context.add_indexed_model Alpha
      
      @context.indexed_models.should == ['Alpha']
    end
  end
  
  describe '#superclass_indexed_models' do
    it "should return indexed model names" do
      @context.stub!(:indexed_models => ['Alpha', 'Beta'])
      
      @context.superclass_indexed_models.should == ['Alpha', 'Beta']
    end
    
    it "should not include classes which have indexed superclasses" do
      @context.stub!(:indexed_models => ['Parent', 'Person'])
      
      @context.superclass_indexed_models.should == ['Person']
    end
  end
end
