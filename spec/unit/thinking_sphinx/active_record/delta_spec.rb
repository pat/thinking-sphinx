require 'spec/spec_helper'

describe "ThinkingSphinx::ActiveRecord::Delta" do
  it "should call the toggle_delta method after a save" do
    @beta = Beta.new(:name => 'beta')
    @beta.stub_method(:toggle_delta => true)
    
    @beta.save
    
    @beta.should have_received(:toggle_delta)
  end
  
  it "should call the toggle_delta method after a save!" do
    @beta = Beta.new(:name => 'beta')
    @beta.stub_method(:toggle_delta => true)
    
    @beta.save!
    
    @beta.should have_received(:toggle_delta)
  end

  describe "suspended_delta method" do
    before :each do
      ThinkingSphinx.stub_method(:deltas_enabled? => true)
      Person.sphinx_indexes.first.delta_object.stub_method(:` => "")
    end

    it "should execute the argument block with deltas disabled" do
      ThinkingSphinx.should_receive(:deltas_enabled=).once.with(false)
      ThinkingSphinx.should_receive(:deltas_enabled=).once.with(true)
      lambda { Person.suspended_delta { raise 'i was called' } }.should(
        raise_error(Exception)
      )
    end

    it "should restore deltas_enabled to its original setting" do
      ThinkingSphinx.stub_method(:deltas_enabled? => false)
      ThinkingSphinx.should_receive(:deltas_enabled=).twice.with(false)
      Person.suspended_delta { 'no-op' }
    end

    it "should restore deltas_enabled to its original setting even if there was an exception" do
      ThinkingSphinx.stub_method(:deltas_enabled? => false)
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
      Person.sphinx_indexes.first.delta_object.stub_method(:` => "")
      
      @person = Person.new
      @person.stub_method(
        :in_core_index?     => false,
        :sphinx_document_id => 1
      )
      
      @client = Riddle::Client.stub_instance(:update => true)
      Riddle::Client.stub_method(:new => @client)
    end
    
    it "shouldn't index if delta indexing is disabled" do
      ThinkingSphinx.stub_method(:deltas_enabled? => false)
      
      @person.send(:index_delta)
      
      Person.sphinx_indexes.first.delta_object.should_not have_received(:`)
      @client.should_not have_received(:update)
    end
    
    it "shouldn't index if index updating is disabled" do
      ThinkingSphinx.stub_method(:updates_enabled? => false)
      
      @person.send(:index_delta)
      
      Person.sphinx_indexes.first.delta_object.should_not have_received(:`)
    end
    
    it "shouldn't index if the environment is 'test'" do
      ThinkingSphinx.unstub_method(:deltas_enabled?)
      ThinkingSphinx.deltas_enabled = nil
      ThinkingSphinx::Configuration.stub_method(:environment => "test")
      
      @person.send(:index_delta)
      
      Person.sphinx_indexes.first.delta_object.should_not have_received(:`)
    end
    
    it "should call indexer for the delta index" do
      @person.send(:index_delta)
      
      Person.sphinx_indexes.first.delta_object.should have_received(:`).with(
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
