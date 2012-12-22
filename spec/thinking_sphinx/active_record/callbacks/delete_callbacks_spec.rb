require 'spec_helper'

describe ThinkingSphinx::ActiveRecord::Callbacks::DeleteCallbacks do
  let(:callbacks)  {
    ThinkingSphinx::ActiveRecord::Callbacks::DeleteCallbacks.new instance
  }
  let(:instance)   { double('instance', :delta? => true) }

  describe '.after_destroy' do
    let(:callbacks) { double('callbacks', :after_destroy => nil) }

    before :each do
      ThinkingSphinx::ActiveRecord::Callbacks::DeleteCallbacks.
        stub :new => callbacks
    end

    it "builds an object from the instance" do
      ThinkingSphinx::ActiveRecord::Callbacks::DeleteCallbacks.
        should_receive(:new).with(instance).and_return(callbacks)

      ThinkingSphinx::ActiveRecord::Callbacks::DeleteCallbacks.
        after_destroy(instance)
    end

    it "invokes after_destroy on the object" do
      callbacks.should_receive(:after_destroy)

      ThinkingSphinx::ActiveRecord::Callbacks::DeleteCallbacks.
        after_destroy(instance)
    end
  end

  describe '#after_destroy' do
    let(:config)     { double('config', :indices_for_references => [index],
      :preload_indices => true) }
    let(:connection) { double('connection', :execute => nil) }
    let(:index)      {
      double('index', :name => 'foo_core', :document_id_for_key => 14)
    }
    let(:instance)   { double('instance', :id => 7) }

    before :each do
      ThinkingSphinx::Configuration.stub :instance => config
      ThinkingSphinx::Connection.stub    :new => connection
      Riddle::Query.stub :update => 'UPDATE STATEMENT'
    end

    it "updates the deleted flag to false" do
      connection.should_receive(:execute).with('UPDATE STATEMENT')

      callbacks.after_destroy
    end

    it "builds the update query for the given index" do
      Riddle::Query.should_receive(:update).
        with('foo_core', anything, anything).and_return('')

      callbacks.after_destroy
    end

    it "builds the update query for the sphinx document id" do
      Riddle::Query.should_receive(:update).
        with(anything, 14, anything).and_return('')

      callbacks.after_destroy
    end

    it "builds the update query for setting sphinx_deleted to true" do
      Riddle::Query.should_receive(:update).
        with(anything, anything, :sphinx_deleted => true).and_return('')

      callbacks.after_destroy
    end

    it "doesn't care about Sphinx errors" do
      connection.stub(:execute).and_raise(Mysql2::Error.new(''))

      lambda { callbacks.after_destroy }.should_not raise_error
    end
  end
end
