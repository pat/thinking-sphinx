require 'spec_helper'

describe ThinkingSphinx::ActiveRecord::Base do
  let(:model) {
    Class.new(ActiveRecord::Base) do
      include ThinkingSphinx::ActiveRecord::Base
    end
  }
  let(:subclassed_model) {
    Class.new(model) do
      include ThinkingSphinx::ActiveRecord::Base
    end
  }

  describe '.search' do
    it "returns a new search object" do
      model.search.should be_a(ThinkingSphinx::Search)
    end

    it "passes through arguments to the search object initializer" do
      ThinkingSphinx::Search.should_receive(:new).with('pancakes', anything)

      model.search 'pancakes'
    end

    it "scopes the search to a given model" do
      ThinkingSphinx::Search.should_receive(:new).
        with(anything, hash_including(:classes => [model]))

      model.search 'pancakes'
    end
  end

  describe '.primary_key_for_sphinx' do
    it "defaults to the model's primary key" do
      model.stub!(:primary_key => :sphinx_id)

      model.primary_key_for_sphinx.should == :sphinx_id
    end

    it "uses a custom column when set" do
      model.stub!(:primary_key => :sphinx_id)
      model.set_primary_key_for_sphinx :custom_sphinx_id

      model.primary_key_for_sphinx.should == :custom_sphinx_id
    end

    it "uses a superclass setting if there's one available" do
      model.set_primary_key_for_sphinx :parent_sphinx_id
      subclassed_model.primary_key_for_sphinx.should == :parent_sphinx_id
    end

    it "defaults to id if no primary key is set" do
      model.stub!(:primary_key => nil)

      model.primary_key_for_sphinx.should == :id
    end
  end

  describe '#save' do
    let(:controller) { double('controller') }
    let(:config)     { double('config', :controller => controller) }
    let(:model)      {
      Class.new do
        def self.after_commit(*callbacks)
          @after_commits ||= []
          @after_commits += callbacks
        end

        def self.after_commits
          @after_commits
        end

        def self.name
          'FooBar'
        end

        def save
          self.class.after_commits.each { |callback| send callback }
        end

        include ThinkingSphinx::ActiveRecord::Base
      end
    }

    before :each do
      ThinkingSphinx::Configuration.stub :instance => config
    end

    it "does not fire a delta index when no indices" do
      config.stub :indices_for_reference => []

      controller.should_not_receive(:index)

      model.new.save
    end

    it "does not fire a delta index when no delta indices" do
      config.stub :indices_for_reference => [double('index', :delta? => false)]

      controller.should_not_receive(:index)

      model.new.save
    end

    it "indexes any delta indices" do
      index = double('index', :delta? => true, :name => 'foo_delta')
      config.stub :indices_for_reference => [index]

      controller.should_receive(:index).with('foo_delta')

      model.new.save
    end

    it "only indexes delta indices" do
      core_index  = double('index', :delta? => false, :name => 'foo_core')
      delta_index = double('index', :delta? => true,  :name => 'foo_delta')
      config.stub :indices_for_reference => [core_index, delta_index]

      controller.should_receive(:index).with('foo_delta')

      model.new.save
    end
  end
end
