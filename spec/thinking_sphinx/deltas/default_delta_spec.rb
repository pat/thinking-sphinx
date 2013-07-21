require 'spec_helper'

describe ThinkingSphinx::Deltas::DefaultDelta do
  let(:delta)   { ThinkingSphinx::Deltas::DefaultDelta.new adapter }
  let(:adapter) {
    double('adapter', :quoted_table_name => 'articles', :quote => 'delta')
  }

  describe '#clause' do
    context 'for a delta source' do
      before :each do
        adapter.stub :boolean_value => 't'
      end

      it "limits results to those flagged as deltas" do
        delta.clause(true).should == "articles.delta = t"
      end
    end
  end

  describe '#delete' do
    let(:connection) { double('connection', :execute => nil) }
    let(:index)      { double('index', :name => 'foo_core',
      :document_id_for_key => 14) }
    let(:instance)   { double('instance', :id => 7) }

    before :each do
      ThinkingSphinx::Connection.stub(:take).and_yield(connection)
      Riddle::Query.stub :update => 'UPDATE STATEMENT'
    end

    it "updates the deleted flag to false" do
      connection.should_receive(:execute).with('UPDATE STATEMENT')

      delta.delete index, instance
    end

    it "builds the update query for the given index" do
      Riddle::Query.should_receive(:update).
        with('foo_core', anything, anything).and_return('')

      delta.delete index, instance
    end

    it "builds the update query for the sphinx document id" do
      Riddle::Query.should_receive(:update).
        with(anything, 14, anything).and_return('')

      delta.delete index, instance
    end

    it "builds the update query for setting sphinx_deleted to true" do
      Riddle::Query.should_receive(:update).
        with(anything, anything, :sphinx_deleted => true).and_return('')

      delta.delete index, instance
    end

    it "doesn't care about Sphinx errors" do
      connection.stub(:execute).and_raise(Mysql2::Error.new(''))

      lambda { delta.delete index, instance }.should_not raise_error
    end
  end

  describe '#index' do
    let(:config)     { double('config', :controller => controller,
      :settings => {}) }
    let(:controller) { double('controller') }

    before :each do
      ThinkingSphinx::Configuration.stub :instance => config
    end

    it "indexes the given index" do
      controller.should_receive(:index).with('foo_delta', :verbose => true)

      delta.index double('index', :name => 'foo_delta')
    end
  end

  describe '#reset_query' do
    it "updates the table to set delta flags to false" do
      adapter.stub(:boolean_value) { |value| value ? 't' : 'f' }
      delta.reset_query.
        should == 'UPDATE articles SET delta = f WHERE delta = t'
    end
  end

  describe '#toggle' do
    let(:instance) { double('instance') }

    it "sets instance's delta flag to true" do
      instance.should_receive(:delta=).with(true)

      delta.toggle(instance)
    end
  end

  describe '#toggled?' do
    let(:instance) { double('instance') }

    it "returns the delta flag value when true" do
      instance.stub! :delta? => true

      delta.toggled?(instance).should be_true
    end

    it "returns the delta flag value when false" do
      instance.stub! :delta? => false

      delta.toggled?(instance).should be_false
    end
  end
end
