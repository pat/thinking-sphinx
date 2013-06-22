require 'spec_helper'

describe ThinkingSphinx::RealTime::Callbacks::RealTimeCallbacks do
  let(:callbacks)  {
    ThinkingSphinx::RealTime::Callbacks::RealTimeCallbacks.new :article
  }
  let(:instance)   { double('instance', :id => 12) }
  let(:config)     { double('config', :indices_for_references => [index]) }
  let(:index)      { double('index', :name => 'my_index', :is_a? => true,
    :document_id_for_key => 123, :fields => [], :attributes => [],
    :conditions => []) }
  let(:connection) { double('connection', :execute => true) }

  before :each do
    ThinkingSphinx::Configuration.stub :instance => config
    ThinkingSphinx::Connection.stub_chain(:pool, :take).and_yield connection
  end

  describe '#after_save' do
    let(:insert)     { double('insert', :to_sql => 'REPLACE INTO my_index') }
    let(:time)       { 1.day.ago }
    let(:field)      { double('field', :name => 'name', :translate => 'Foo') }
    let(:attribute)  { double('attribute', :name => 'created_at',
      :translate => time) }

    before :each do
      ThinkingSphinx::Configuration.stub :instance => config
      Riddle::Query::Insert.stub :new => insert
      insert.stub :replace! => insert
      index.stub :fields => [field], :attributes => [attribute]
    end

    it "creates an insert statement with all fields and attributes" do
      Riddle::Query::Insert.should_receive(:new).
        with('my_index', ['id', 'name', 'created_at'], [123, 'Foo', time]).
        and_return(insert)

      callbacks.after_save instance
    end

    it "switches the insert to a replace statement" do
      insert.should_receive(:replace!).and_return(insert)

      callbacks.after_save instance
    end

    it "sends the insert through to the server" do
      connection.should_receive(:execute).with('REPLACE INTO my_index')

      callbacks.after_save instance
    end

    context 'with a given path' do
      let(:callbacks)  {
        ThinkingSphinx::RealTime::Callbacks::RealTimeCallbacks.new(
          :article, [:user]
        )
      }
      let(:instance)   { double('instance', :id => 12, :user => user) }
      let(:user)       { double('user', :id => 13) }

      it "creates an insert statement with all fields and attributes" do
        Riddle::Query::Insert.should_receive(:new).
          with('my_index', ['id', 'name', 'created_at'], [123, 'Foo', time]).
          and_return(insert)

        callbacks.after_save instance
      end

      it "gets the document id for the user object" do
        index.should_receive(:document_id_for_key).with(13).and_return(123)

        callbacks.after_save instance
      end

      it "translates values for the user object" do
        field.should_receive(:translate).with(user).and_return('Foo')

        callbacks.after_save instance
      end
    end

    context 'with a path returning multiple objects' do
      let(:callbacks)  {
        ThinkingSphinx::RealTime::Callbacks::RealTimeCallbacks.new(
          :article, [:readers]
        )
      }
      let(:instance)   { double('instance', :id => 12,
        :readers => [user_a, user_b]) }
      let(:user_a)     { double('user', :id => 13) }
      let(:user_b)     { double('user', :id => 14) }

      it "creates insert statements with all fields and attributes" do
        Riddle::Query::Insert.should_receive(:new).twice.
          with('my_index', ['id', 'name', 'created_at'], [123, 'Foo', time]).
          and_return(insert)

        callbacks.after_save instance
      end

      it "gets the document id for each reader" do
        index.should_receive(:document_id_for_key).with(13).and_return(123)
        index.should_receive(:document_id_for_key).with(14).and_return(123)

        callbacks.after_save instance
      end

      it "translates values for each reader" do
        field.should_receive(:translate).with(user_a).and_return('Foo')
        field.should_receive(:translate).with(user_b).and_return('Foo')

        callbacks.after_save instance
      end
    end
  end
end
