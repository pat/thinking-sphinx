require 'spec/spec_helper'

describe ThinkingSphinx::Delta do
  it "should call the toggle_delta method after a save" do
    @beta = Beta.new(:name => 'beta')
    @beta.should_receive(:toggle_delta).and_return(true)
    
    @beta.save
  end
  
  it "should call the toggle_delta method after a save!" do
    @beta = Beta.new(:name => 'beta')
    @beta.should_receive(:toggle_delta).and_return(true)
    
    @beta.save!
  end
  
  describe "toggle_delta method" do
    it "should set the delta value to true" do
      @person = Person.new
      
      @person.delta.should be_false
      @person.send(:toggle_delta)
      @person.delta.should be_true
    end
  end
  
  describe "index_delta method" do
    before :each do
      ThinkingSphinx::Configuration.stub!(:environment => "spec")
      ThinkingSphinx.deltas_enabled   = true
      ThinkingSphinx.updates_enabled  = true
      ThinkingSphinx.stub!(:sphinx_running? => true)
      Person.delta_object.stub!(:` => "", :toggled => true)
      ThinkingSphinx::Index.stub!(:toggle_deleted => true)
      
      @person = Person.new
      Person.stub!(:search_for_id => false)
      @person.stub!(:sphinx_document_id => 1)
      
      @client = Riddle::Client.new
      @client.stub!(:update => true)
      ThinkingSphinx::Configuration.instance.stub!(:client => @client)
    end
    
    it "shouldn't index if delta indexing is disabled" do
      ThinkingSphinx.deltas_enabled = false
      Person.sphinx_indexes.first.delta_object.should_not_receive(:`)
      @client.should_not_receive(:update)
      
      @person.send(:index_delta)
    end
    
    it "shouldn't index if index updating is disabled" do
      ThinkingSphinx.updates_enabled = false
      Person.sphinx_indexes.first.delta_object.should_not_receive(:`)
      
      @person.send(:index_delta)
    end
    
    it "shouldn't index if the environment is 'test'" do
      ThinkingSphinx.deltas_enabled = nil
      ThinkingSphinx::Configuration.stub!(:environment => "test")
      Person.sphinx_indexes.first.delta_object.should_not_receive(:`)
      
      @person.send(:index_delta)
    end
    
    it "should call indexer for the delta index" do
      Person.sphinx_indexes.first.delta_object.should_receive(:`).with(
        "#{ThinkingSphinx::Configuration.instance.bin_path}indexer --config #{ThinkingSphinx::Configuration.instance.config_file} --rotate person_delta"
      )
      
      @person.send(:index_delta)
    end
    
    it "should update the deleted attribute" do
      ThinkingSphinx::Index.should_receive(:toggle_deleted).
        with('person_core', 1)
      
      @person.send(:index_delta)
    end
  end
end
