require 'spec/spec_helper'

class MockModel
  include ThinkingSphinx::Base
end

class SubMockModel < MockModel
  #
end

class FooModel
  #
end

describe ThinkingSphinx::Base do
  before :each do
    MockModel.sphinx_indexes.clear
    MockModel.sphinx_index_blocks.clear
  end
  
  after :each do
    ThinkingSphinx.context.indexed_models.delete 'MockModel'
  end
  
  describe '.define_index' do
    it "should not evaluate the index block" do
      lambda {
        MockModel.define_index { raise StandardError }
      }.should_not raise_error
    end
    
    it "should add the model to the context collection" do
      MockModel.define_index { }
      
      ThinkingSphinx.context.indexed_models.should include('MockModel')
    end
    
    it "should call add_initial_sphinx_callbacks" do
      MockModel.should_receive(:add_initial_sphinx_callbacks)
      
      MockModel.define_index { }
    end
    
    it "should only call add_initial_sphinx_callbacks once" do
      MockModel.should_receive(:add_initial_sphinx_callbacks).once
      
      MockModel.define_index { }
      MockModel.define_index { }
    end
  end
  
  describe '.process_indexes' do
    before :each do
      @index = stub('index', :delta? => false)
      ThinkingSphinx::Index::Builder.stub!(:generate => @index)
    end
    
    it "should process the define_index blocks" do
      MockModel.define_index { indexes :name }
      MockModel.sphinx_indexes.length.should == 0
      
      MockModel.process_indexes
      MockModel.sphinx_indexes.length.should == 1
    end
    
    it "should not re-add indexes" do
      MockModel.define_index { indexes :name }
      MockModel.process_indexes
      MockModel.process_indexes
      
      MockModel.sphinx_indexes.length.should == 1
    end
    
    it "should do nothing if defining indexes is disabled" do
      ThinkingSphinx.define_indexes = false
      
      MockModel.define_index { indexes :name }
      MockModel.process_indexes
      
      MockModel.sphinx_indexes.should be_empty
      
      ThinkingSphinx.define_indexes = true
    end
    
    it "should pass the given name to the index" do
      ThinkingSphinx::Index::Builder.should_receive(:generate).
        with(anything, 'custom').and_return(@index)
      
      MockModel.define_index('custom') { indexes :name }
      MockModel.process_indexes
    end
    
    it "should call add_standard_sphinx_callbacks" do
      MockModel.should_receive(:add_standard_sphinx_callbacks)
      
      MockModel.define_index { indexes :name }
      MockModel.process_indexes
    end
    
    it "should only call add_standard_sphinx_callbacks once" do
      MockModel.should_receive(:add_standard_sphinx_callbacks).once
      
      MockModel.define_index { indexes :name }
      MockModel.define_index { indexes :name }
      MockModel.process_indexes
    end
    
    it "should not call add_delta_sphinx_callbacks for default indexes" do
      MockModel.should_not_receive(:add_delta_sphinx_callbacks)
      
      MockModel.define_index { indexes :name }
      MockModel.process_indexes
    end
    
    it "should call add_delta_sphinx_callbacks for delta'd indexes" do
      MockModel.should_receive(:add_delta_sphinx_callbacks)
      
      @index.stub!(:delta? => true)
      MockModel.define_index { indexes :name }
      MockModel.process_indexes
    end
    
    it "should only call add_delta_sphinx_callbacks once" do
      MockModel.should_receive(:add_delta_sphinx_callbacks).once
      
      @index.stub!(:delta? => true)
      MockModel.define_index { indexes :name }
      MockModel.define_index { indexes :name }
      MockModel.process_indexes
    end
  end
  
  describe '.to_crc32' do
    it "should return the CRC32 value of the class name" do
      MockModel.to_crc32.should == 3355722184
    end
  end
    
  describe '.to_crc32s' do
    it "should include the CRC32 value of the class name" do
      MockModel.to_crc32s.should include(3355722184)
    end
    
    it "should include CRC32 values of subclass names" do
      MockModel.to_crc32s.should include(1146761481)
    end
  end
  
  describe '.sphinx_offset' do
    before :each do
      @context = ThinkingSphinx.context
    end
    
    it "should return the index of the model's name in all known indexed models" do
      @context.stub!(:indexed_models => ['FooModel', 'MockModel'])
      
      MockModel.sphinx_offset.should  == 1
    end
    
    it "should ignore classes that have indexed superclasses" do
      @context.stub!(:indexed_models => ['FooModel', 'SubMockModel', 'MockModel'])
      
      MockModel.sphinx_offset.should == 1
    end
    
    it "should respect first known indexed parents" do
      @context.stub!(:indexed_models => ['FooModel', 'MockModel', 'SubMockModel'])
      
      SubMockModel.sphinx_offset.should == 1
    end
  end
  
  describe '.sphinx_index_names' do
    it "should return the all index names" do
      foo = stub('index', :all_names => ['one'])
      bar = stub('index', :all_names => ['two', 'three'])
      MockModel.stub!(:sphinx_indexes => [foo, bar])
      
      MockModel.sphinx_index_names.should == ['one', 'two', 'three']
    end
    
    it "should return the superclass with an index definition" do
      Parent.sphinx_index_names.should == ['person_core', 'person_delta']
    end
  end
  
  describe '.indexed_by_sphinx?' do
    it "should return true if there is at least one index on the model" do
      MockModel.stub!(:sphinx_indexes => [stub('index')])
      
      MockModel.should be_indexed_by_sphinx
    end
    
    it "should return false if there are no indexes on the model" do
      MockModel.stub!(:sphinx_indexes => [])
      
      MockModel.should_not be_indexed_by_sphinx
    end
  end
  
  describe '.delta_indexed_by_sphinx?' do
    it "should return true if there is at least one delta index on the model" do
      MockModel.stub!(:sphinx_indexes => [stub('index', :delta? => true)])
      
      MockModel.should be_delta_indexed_by_sphinx
    end
    
    it "should return false if there are no delta indexes on the model" do
      MockModel.stub!(:sphinx_indexes => [stub('index', :delta? => false)])
      
      MockModel.should_not be_delta_indexed_by_sphinx
    end
  end
  
  describe '.core_index_names' do
    it "should return each index's core name" do
      MockModel.stub!(:sphinx_indexes => [
        stub('index', :core_name => 'foo'),
        stub('index', :core_name => 'bar')
      ])
      
      MockModel.core_index_names.should == ['foo', 'bar']
    end
  end
  
  describe '.delta_index_names' do
    it "should return index delta names, for indexes with deltas enabled" do
      MockModel.stub!(:sphinx_indexes => [
        stub('index', :delta_name => 'foo', :delta? => true),
        stub('index', :delta_name => 'bar', :delta? => false)
      ])
      
      MockModel.delta_index_names.should == ['foo']
    end
  end
  
  describe '.has_sphinx_indexes?' do
    it "should return true if there are sphinx indexes defined" do
      MockModel.sphinx_indexes.replace [stub('index')]
      MockModel.sphinx_index_blocks.replace []
      
      MockModel.should have_sphinx_indexes
    end
    
    it "should return true if there are sphinx index blocks defined" do
      MockModel.sphinx_indexes.replace []
      MockModel.sphinx_index_blocks.replace [stub('lambda')]
      
      MockModel.should have_sphinx_indexes
    end
    
    it "should return false if there are no sphinx indexes or blocks" do
      MockModel.sphinx_indexes.clear
      MockModel.sphinx_index_blocks.clear
      
      MockModel.should_not have_sphinx_indexes
    end
  end
  
  describe "suspended_delta method" do
    before :each do
      ThinkingSphinx.deltas_enabled = true
      Person.sphinx_indexes.first.delta_object.stub!(:` => "")
    end

    it "should execute the argument block with deltas disabled" do
      ThinkingSphinx.should_receive(:deltas_enabled=).once.with(false)
      ThinkingSphinx.should_receive(:deltas_enabled=).once.with(true)
      lambda { Person.suspended_delta { raise 'i was called' } }.should(
        raise_error(Exception)
      )
    end

    it "should restore deltas_enabled to its original setting" do
      ThinkingSphinx.deltas_enabled = false
      ThinkingSphinx.should_receive(:deltas_enabled=).twice.with(false)
      Person.suspended_delta { 'no-op' }
    end

    it "should restore deltas_enabled to its original setting even if there was an exception" do
      ThinkingSphinx.deltas_enabled = false
      ThinkingSphinx.should_receive(:deltas_enabled=).twice.with(false)
      lambda { Person.suspended_delta { raise 'bad error' } }.should(
        raise_error(Exception)
      )
    end

    it "should reindex by default after the code block is run" do
      Person.should_receive(:index_delta)
      Person.suspended_delta { 'no-op' }
    end
    
    it "should not reindex after the code block if false is passed in" do
      Person.should_not_receive(:index_delta)
      Person.suspended_delta(false) { 'no-op' }
    end
  end
  
  describe '#toggle_deleted' do
    before :each do
      ThinkingSphinx.context.stub!(:indexed_models => ['MockModel'])
    end
    
    it "call toggle_deleted on each index" do
      MockModel.stub!(:sphinx_indexes => [stub('index'), stub('index')])
      MockModel.sphinx_indexes.each do |index|
        index.should_receive(:toggle_deleted)
      end
      
      MockModel.new.toggle_deleted
    end
    
    it "should call an index's toggle_deleted with the sphinx document id" do
      model = MockModel.new
      model.stub!(:sphinx_document_id => 5)
      
      index = stub('index')
      index.should_receive(:toggle_deleted).with(5)
      MockModel.stub!(:sphinx_indexes => [index])
      
      model.toggle_deleted
    end
  end
  
  describe '#sphinx_document_id' do
    it "should return the primary key with the expected offset" do
      model = MockModel.new
      model.stub!(:primary_key_for_sphinx => 5)
      
      MockModel.stub!(:sphinx_offset => 3)
      count = ThinkingSphinx.context.indexed_models.length
      
      model.sphinx_document_id.should == (5 * count) + 3
    end
  end
end
