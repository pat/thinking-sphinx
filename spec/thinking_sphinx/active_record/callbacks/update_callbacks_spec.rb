module ThinkingSphinx
  module ActiveRecord
    module Callbacks; end
  end
end

require 'active_support/core_ext/string/inflections'
require 'thinking_sphinx/callbacks'
require 'thinking_sphinx/errors'
require 'thinking_sphinx/active_record/callbacks/update_callbacks'

describe ThinkingSphinx::ActiveRecord::Callbacks::UpdateCallbacks do
  describe '#after_update' do
    let(:callbacks)     {
      ThinkingSphinx::ActiveRecord::Callbacks::UpdateCallbacks.new instance }
    let(:instance)      { double('instance', :class => klass, :id => 2) }
    let(:klass)         { double(:name => 'Article') }
    let(:configuration) { double('configuration',
      :settings => {'attribute_updates' => true},
      :indices_for_references => [index]) }
    let(:connection)    { double('connection', :execute => '') }
    let(:index)         { double 'index', :name => 'article_core',
      :sources => [source], :document_id_for_key => 3, :distributed? => false,
      :type => 'plain'}
    let(:source)        { double('source', :attributes => []) }

    before :each do
      stub_const 'ThinkingSphinx::Configuration',
        double(:instance => configuration)
      stub_const 'ThinkingSphinx::Connection', double
      stub_const 'Riddle::Query', double(:update => 'SphinxQL')

      allow(ThinkingSphinx::Connection).to receive(:take).and_yield(connection)

      source.attributes.replace([
        double(:name => 'foo', :updateable? => true,
          :columns => [double(:__name => 'foo_column')]),
        double(:name => 'bar', :updateable? => true, :value_for => 7,
          :columns => [double(:__name => 'bar_column')]),
        double(:name => 'baz', :updateable? => false)
      ])

      allow(instance).to receive_messages :changed => ['bar_column', 'baz'], :bar_column => 7
    end

    it "does not send any updates to Sphinx if updates are disabled" do
      configuration.settings['attribute_updates'] = false

      expect(connection).not_to receive(:execute)

      callbacks.after_update
    end

    it "builds an update query with only updateable attributes that have changed" do
      expect(Riddle::Query).to receive(:update).
        with('article_core', 3, 'bar' => 7).and_return('SphinxQL')

      callbacks.after_update
    end

    it "sends the update query through to Sphinx" do
      expect(connection).to receive(:execute).with('SphinxQL')

      callbacks.after_update
    end

    it "doesn't care if the update fails at Sphinx's end" do
      allow(connection).to receive(:execute).
        and_raise(ThinkingSphinx::ConnectionError.new(''))

      expect { callbacks.after_update }.not_to raise_error
    end

    it 'does nothing if callbacks are suspended' do
      ThinkingSphinx::Callbacks.suspend!

      expect(connection).not_to receive(:execute)

      callbacks.after_update

      ThinkingSphinx::Callbacks.resume!
    end
  end
end
