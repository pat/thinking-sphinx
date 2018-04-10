# frozen_string_literal: true

require 'spec_helper'

describe ThinkingSphinx::Deletion do
  describe '.perform' do
    let(:connection) { double('connection', :execute => nil) }
    let(:index)      { double('index', :name => 'foo_core',
      :document_id_for_key => 14, :type => 'plain', :distributed? => false) }

    before :each do
      allow(ThinkingSphinx::Connection).to receive(:take).and_yield(connection)
      allow(Riddle::Query).to receive_messages :update => 'UPDATE STATEMENT'
    end

    context 'index is SQL-backed' do
      it "updates the deleted flag to false" do
        expect(connection).to receive(:execute).
          with('UPDATE foo_core SET sphinx_deleted = 1 WHERE id IN (14)')

        ThinkingSphinx::Deletion.perform index, 7
      end

      it "doesn't care about Sphinx errors" do
        allow(connection).to receive(:execute).
          and_raise(ThinkingSphinx::ConnectionError.new(''))

        expect {
          ThinkingSphinx::Deletion.perform index, 7
        }.not_to raise_error
      end
    end

    context "index is real-time" do
      before :each do
        allow(index).to receive_messages :type => 'rt'
      end

      it "deletes the record to false" do
        expect(connection).to receive(:execute).
          with('DELETE FROM foo_core WHERE id = 14')

        ThinkingSphinx::Deletion.perform index, 7
      end

      it "doesn't care about Sphinx errors" do
        allow(connection).to receive(:execute).
          and_raise(ThinkingSphinx::ConnectionError.new(''))

        expect {
          ThinkingSphinx::Deletion.perform index, 7
        }.not_to raise_error
      end
    end
  end
end
