require 'spec/spec_helper'

describe "ThinkingSphinx::ActiveRecord::Delta" do
  it "should call the toggle_delta method after a save" do
    @beta = Beta.new
    @beta.stub_method(:toggle_delta => true)
    
    @beta.save
    
    @beta.should have_received(:toggle_delta)
  end
  
  it "should call the toggle_delta method after a save!" do
    @beta = Beta.new
    @beta.stub_method(:toggle_delta => true)
    
    @beta.save!
    
    @beta.should have_received(:toggle_delta)
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
      ThinkingSphinx::Configuration.stub_method(:environment => "spec")
      ThinkingSphinx.stub_method(:deltas_enabled? => true)
      
      @person = Person.find(:first)
      Person.stub_method(:system => true)
      @person.stub_method(:in_core_index? => false)
      
      @client = Riddle::Client.stub_instance(:update => true)
      Riddle::Client.stub_method(:new => @client)
    end
    
    it "shouldn't index if delta indexing is disabled" do
      ThinkingSphinx.stub_method(:deltas_enabled? => false)
      
      @person.send(:index_delta)
      
      Person.should_not have_received(:system)
      @client.should_not have_received(:update)
    end
    
    it "shouldn't index if index updating is disabled" do
      ThinkingSphinx.stub_method(:updates_enabled? => false)
      
      @person.send(:index_delta)
      
      Person.should_not have_received(:system)
    end
    
    it "shouldn't index if the environment is 'test'" do
      ThinkingSphinx.unstub_method(:deltas_enabled?)
      ThinkingSphinx.deltas_enabled = nil
      ThinkingSphinx::Configuration.stub_method(:environment => "test")
      
      @person.send(:index_delta)
      
      Person.should_not have_received(:system)
    end
    
    it "should call indexer for the delta index" do
      @person.send(:index_delta)
      
      Person.should have_received(:system).with(
        "#{ThinkingSphinx::Configuration.instance.bin_path}indexer --config #{ThinkingSphinx::Configuration.instance.config_file} --rotate person_delta"
      )
    end
    
    it "shouldn't update the deleted attribute if not in the index" do
      @person.send(:index_delta)
      
      @client.should_not have_received(:update)
    end
    
    it "should update the deleted attribute if in the core index" do
      @person.stub_method(:in_core_index? => true)
      
      @person.send(:index_delta)
      
      @client.should have_received(:update)
    end
  end
end
