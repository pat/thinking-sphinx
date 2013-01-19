require 'spec_helper'

describe "ThinkingSphinx::ActiveRecord::Delta" do
  it "should call the toggle_delta method after a save" do
    @beta = Beta.new(:name => 'beta')
    @beta.should_receive(:toggle_delta).at_least(1).times.and_return(true)

    @beta.save
  end

  it "should call the toggle_delta method after a save!" do
    @beta = Beta.new(:name => 'beta')
    @beta.should_receive(:toggle_delta).at_least(1).times.and_return(true)

    @beta.save!
  end

  describe "suspended_delta method" do
    before :each do
      ThinkingSphinx.deltas_suspended = false
      Person.sphinx_indexes.first.delta_object.stub!(:` => "")
    end

    it "should execute the argument block with deltas disabled" do
      ThinkingSphinx.should_receive(:deltas_suspended=).once.with(true)
      ThinkingSphinx.should_receive(:deltas_suspended=).once.with(false)
      lambda { Person.suspended_delta { raise 'i was called' } }.should(
        raise_error(Exception)
      )
    end

    it "should restore deltas_enabled to its original setting" do
      ThinkingSphinx.deltas_suspended = true
      ThinkingSphinx.should_receive(:deltas_suspended=).twice.with(true)
      Person.suspended_delta { 'no-op' }
    end

    it "should restore deltas_enabled to its original setting even if there was an exception" do
      ThinkingSphinx.deltas_suspended = true
      ThinkingSphinx.should_receive(:deltas_suspended=).twice.with(true)
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
      ThinkingSphinx::Configuration.stub!(:environment => "spec")
      ThinkingSphinx.deltas_enabled   = true
      ThinkingSphinx.updates_enabled  = true
      ThinkingSphinx.stub!(:sphinx_running? => true)
      Person.delta_objects.first.stub!(:` => "", :toggled => true)

      @person = Person.new
      Person.stub!(:search_for_id => false)
      @person.stub!(:sphinx_document_id => 1)

      @client = Riddle::Client.new
      @client.stub!(:update => true)
      ThinkingSphinx::Connection.stub(:take).and_yield @client
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
        "#{ThinkingSphinx::Configuration.instance.bin_path}indexer --config \"#{ThinkingSphinx::Configuration.instance.config_file}\" --rotate person_delta"
      )

      @person.send(:index_delta)
    end

    it "should update the deleted attribute if in the core index" do
      Person.stub!(:search_for_id => true)
      @client.should_receive(:update)

      @person.send(:index_delta)
    end
  end
end
