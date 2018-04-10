# frozen_string_literal: true

require 'spec_helper'

describe ThinkingSphinx::Deltas::DefaultDelta do
  let(:delta)   { ThinkingSphinx::Deltas::DefaultDelta.new adapter }
  let(:adapter) {
    double('adapter', :quoted_table_name => 'articles', :quote => 'delta')
  }

  describe '#clause' do
    context 'for a delta source' do
      before :each do
        allow(adapter).to receive_messages :boolean_value => 't'
      end

      it "limits results to those flagged as deltas" do
        expect(delta.clause(true)).to eq("articles.delta = t")
      end
    end
  end

  describe '#delete' do
    let(:connection) { double('connection', :execute => nil) }
    let(:index)      { double('index', :name => 'foo_core',
      :document_id_for_instance => 14) }
    let(:instance)   { double('instance', :id => 7) }

    before :each do
      allow(ThinkingSphinx::Connection).to receive(:take).and_yield(connection)
      allow(Riddle::Query).to receive_messages :update => 'UPDATE STATEMENT'
    end

    it "updates the deleted flag to false" do
      expect(connection).to receive(:execute).with('UPDATE STATEMENT')

      delta.delete index, instance
    end

    it "builds the update query for the given index" do
      expect(Riddle::Query).to receive(:update).
        with('foo_core', anything, anything).and_return('')

      delta.delete index, instance
    end

    it "builds the update query for the sphinx document id" do
      expect(Riddle::Query).to receive(:update).
        with(anything, 14, anything).and_return('')

      delta.delete index, instance
    end

    it "builds the update query for setting sphinx_deleted to true" do
      expect(Riddle::Query).to receive(:update).
        with(anything, anything, :sphinx_deleted => true).and_return('')

      delta.delete index, instance
    end

    it "doesn't care about Sphinx errors" do
      allow(connection).to receive(:execute).
        and_raise(ThinkingSphinx::ConnectionError.new(''))

      expect { delta.delete index, instance }.not_to raise_error
    end
  end

  describe '#index' do
    let(:config)     { double('config', :controller => controller,
      :settings => {}) }
    let(:controller) { double('controller') }
    let(:commander)  { double('commander', :call => true) }

    before :each do
      stub_const 'ThinkingSphinx::Commander', commander

      allow(ThinkingSphinx::Configuration).to receive_messages :instance => config
    end

    it "indexes the given index" do
      expect(commander).to receive(:call).with(
        :index_sql, config, :indices => ['foo_delta'], :verbose => false
      )

      delta.index double('index', :name => 'foo_delta')
    end
  end

  describe '#reset_query' do
    it "updates the table to set delta flags to false" do
      allow(adapter).to receive(:boolean_value) { |value| value ? 't' : 'f' }
      expect(delta.reset_query).
        to eq('UPDATE articles SET delta = f WHERE delta = t')
    end
  end

  describe '#toggle' do
    let(:instance) { double('instance') }

    it "sets instance's delta flag to true" do
      expect(instance).to receive(:delta=).with(true)

      delta.toggle(instance)
    end
  end

  describe '#toggled?' do
    let(:instance) { double('instance') }

    it "returns the delta flag value when true" do
      allow(instance).to receive_messages :delta? => true

      expect(delta.toggled?(instance)).to be_truthy
    end

    it "returns the delta flag value when false" do
      allow(instance).to receive_messages :delta? => false

      expect(delta.toggled?(instance)).to be_falsey
    end
  end
end
