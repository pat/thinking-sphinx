require 'spec_helper'

describe ThinkingSphinx::Deletion do
  describe '.perform' do
    let(:connection) { double('connection', :execute => nil) }
    let(:index)      { double('index', :name => 'foo_core',
      :document_id_for_key => 14, :type => 'plain') }
    let(:instance)   { double('instance', :id => 7) }

    before :each do
      ThinkingSphinx::Connection.stub(:take).and_yield(connection)
      Riddle::Query.stub :update => 'UPDATE STATEMENT'
    end

    context 'index is SQL-backed' do
      it "updates the deleted flag to false" do
        connection.should_receive(:execute).with('UPDATE STATEMENT')

        ThinkingSphinx::Deletion.perform index, instance
      end

      it "builds the update query for the given index" do
        Riddle::Query.should_receive(:update).
          with('foo_core', anything, anything).and_return('')

        ThinkingSphinx::Deletion.perform index, instance
      end

      it "builds the update query for the sphinx document id" do
        Riddle::Query.should_receive(:update).
          with(anything, 14, anything).and_return('')

        ThinkingSphinx::Deletion.perform index, instance
      end

      it "builds the update query for setting sphinx_deleted to true" do
        Riddle::Query.should_receive(:update).
          with(anything, anything, :sphinx_deleted => true).and_return('')

        ThinkingSphinx::Deletion.perform index, instance
      end

      it "doesn't care about Sphinx errors" do
        connection.stub(:execute).and_raise(Mysql2::Error.new(''))

        lambda {
          ThinkingSphinx::Deletion.perform index, instance
        }.should_not raise_error
      end
    end

    context "index is real-time" do
      before :each do
        index.stub :type => 'rt'
      end

      it "deletes the record to false" do
        connection.should_receive(:execute).
          with('DELETE FROM foo_core WHERE id = 14')

        ThinkingSphinx::Deletion.perform index, instance
      end

      it "doesn't care about Sphinx errors" do
        connection.stub(:execute).and_raise(Mysql2::Error.new(''))

        lambda {
          ThinkingSphinx::Deletion.perform index, instance
        }.should_not raise_error
      end
    end
  end
end
