require 'spec_helper'

describe ThinkingSphinx::Deletion do
  describe '.perform' do
    let(:connection) { double('connection', :execute => nil) }
    let(:index)      { double('index', :name => 'foo_core',
      :document_id_for_key => 14, :type => 'plain', :distributed? => false) }

    before :each do
      ThinkingSphinx::Connection.stub(:take).and_yield(connection)
      Riddle::Query.stub :update => 'UPDATE STATEMENT'
    end

    context 'index is SQL-backed' do
      it "updates the deleted flag to false" do
        connection.should_receive(:execute).with <<-SQL
UPDATE foo_core
SET sphinx_deleted = 1
WHERE id IN (14)
        SQL

        ThinkingSphinx::Deletion.perform index, 7
      end

      it "doesn't care about Sphinx errors" do
        connection.stub(:execute).
          and_raise(ThinkingSphinx::ConnectionError.new(''))

        lambda {
          ThinkingSphinx::Deletion.perform index, 7
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

        ThinkingSphinx::Deletion.perform index, 7
      end

      it "doesn't care about Sphinx errors" do
        connection.stub(:execute).
          and_raise(ThinkingSphinx::ConnectionError.new(''))

        lambda {
          ThinkingSphinx::Deletion.perform index, 7
        }.should_not raise_error
      end
    end
  end
end
