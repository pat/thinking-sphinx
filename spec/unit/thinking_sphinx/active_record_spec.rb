require 'spec/spec_helper'

describe "ThinkingSphinx::ActiveRecord" do
  describe "define_index method" do
    before :each do
      module TestModule
        class TestModel < ActiveRecord::Base; end
      end
      
      TestModule::TestModel.stub_methods(
        :before_save  => true,
        :after_commit => true
      )
      
      @index = ThinkingSphinx::Index.stub_instance(:delta? => false)
      ThinkingSphinx::Index.stub_method(:new => @index)
    end
    
    after :each do
      # Remove the class so we can redefine it
      TestModule.send(:remove_const, :TestModel)
    end
    
    it "should add a new index to the model" do
      TestModule::TestModel.define_index do; end
      
      TestModule::TestModel.indexes.length.should == 1
    end
    
    it "should add to ThinkingSphinx.indexed_models if the model doesn't already exist in the array" do
      TestModule::TestModel.define_index do; end
      
      ThinkingSphinx.indexed_models.should include("TestModule::TestModel")
    end
    
    it "shouldn't add to ThinkingSphinx.indexed_models if the model already exists in the array" do
      TestModule::TestModel.define_index do; end
      
      ThinkingSphinx.indexed_models.select { |model|
        model == "TestModule::TestModel"
      }.length.should == 1
      
      TestModule::TestModel.define_index do; end
      
      ThinkingSphinx.indexed_models.select { |model|
        model == "TestModule::TestModel"
      }.length.should == 1
    end
    
    it "should add before_save and after_commit hooks to the model if delta indexing is enabled" do
      @index.stub_method(:delta? => true)
      
      TestModule::TestModel.define_index do; end
      
      TestModule::TestModel.should have_received(:before_save)
      TestModule::TestModel.should have_received(:after_commit)
    end
    
    it "should not add before_save and after_commit hooks to the model if delta indexing is disabled" do
      TestModule::TestModel.define_index do; end
      
      TestModule::TestModel.should_not have_received(:before_save)
      TestModule::TestModel.should_not have_received(:after_commit)
    end
    
    it "should return the new index" do
      TestModule::TestModel.define_index.should == @index
    end
  end
  
  describe "to_crc32 method" do
    it "should return an integer" do
      Person.to_crc32.should be_a_kind_of(Integer)
    end
  end
end