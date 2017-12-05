# frozen_string_literal: true

require 'spec_helper'

describe ThinkingSphinx::RealTime::Callbacks::RealTimeCallbacks do
  let(:callbacks)  {
    ThinkingSphinx::RealTime::Callbacks::RealTimeCallbacks.new :article
  }
  let(:instance)   { double('instance', :id => 12, :persisted? => true) }
  let(:config)     { double('config', :indices_for_references => [index],
    :settings => {}) }
  let(:index)      { double('index', :name => 'my_index', :is_a? => true,
    :document_id_for_key => 123, :fields => [], :attributes => [],
    :conditions => []) }
  let(:connection) { double('connection', :execute => true) }

  before :each do
    allow(ThinkingSphinx::Configuration).to receive_messages :instance => config
    allow(ThinkingSphinx::Connection).to receive_message_chain(:pool, :take).and_yield connection
  end

  describe '#after_save, #after_commit' do
    let(:insert)     { double('insert', :to_sql => 'REPLACE INTO my_index') }
    let(:time)       { 1.day.ago }
    let(:field)      { double('field', :name => 'name', :translate => 'Foo') }
    let(:attribute)  { double('attribute', :name => 'created_at',
      :translate => time) }

    before :each do
      allow(ThinkingSphinx::Configuration).to receive_messages :instance => config
      allow(Riddle::Query::Insert).to receive_messages :new => insert
      allow(insert).to receive_messages :replace! => insert
      allow(index).to receive_messages :fields => [field], :attributes => [attribute]
    end

    it "creates an insert statement with all fields and attributes" do
      expect(Riddle::Query::Insert).to receive(:new).
        with('my_index', ['id', 'name', 'created_at'], [[123, 'Foo', time]]).
        and_return(insert)

      callbacks.after_save instance
    end

    it "switches the insert to a replace statement" do
      expect(insert).to receive(:replace!).and_return(insert)

      callbacks.after_save instance
    end

    it "sends the insert through to the server" do
      expect(connection).to receive(:execute).with('REPLACE INTO my_index')

      callbacks.after_save instance
    end

    it "creates an insert statement with all fields and attributes" do
      expect(Riddle::Query::Insert).to receive(:new).
        with('my_index', ['id', 'name', 'created_at'], [[123, 'Foo', time]]).
        and_return(insert)

      callbacks.after_commit instance
    end

    it "switches the insert to a replace statement" do
      expect(insert).to receive(:replace!).and_return(insert)

      callbacks.after_commit instance
    end

    it "sends the insert through to the server" do
      expect(connection).to receive(:execute).with('REPLACE INTO my_index')

      callbacks.after_commit instance
    end

    context 'with a given path' do
      let(:callbacks)  {
        ThinkingSphinx::RealTime::Callbacks::RealTimeCallbacks.new(
          :article, [:user]
        )
      }
      let(:instance)   { double('instance', :id => 12, :user => user) }
      let(:user)       { double('user', :id => 13, :persisted? => true) }

      it "creates an insert statement with all fields and attributes" do
        expect(Riddle::Query::Insert).to receive(:new).
          with('my_index', ['id', 'name', 'created_at'], [[123, 'Foo', time]]).
          and_return(insert)

        callbacks.after_save instance
      end

      it "gets the document id for the user object" do
        expect(index).to receive(:document_id_for_key).with(13).and_return(123)

        callbacks.after_save instance
      end

      it "translates values for the user object" do
        expect(field).to receive(:translate).with(user).and_return('Foo')

        callbacks.after_save instance
      end

      it "creates an insert statement with all fields and attributes" do
        expect(Riddle::Query::Insert).to receive(:new).
          with('my_index', ['id', 'name', 'created_at'], [[123, 'Foo', time]]).
          and_return(insert)

        callbacks.after_commit instance
      end

      it "gets the document id for the user object" do
        expect(index).to receive(:document_id_for_key).with(13).and_return(123)

        callbacks.after_commit instance
      end

      it "translates values for the user object" do
        expect(field).to receive(:translate).with(user).and_return('Foo')

        callbacks.after_commit instance
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
      let(:user_a)     { double('user', :id => 13, :persisted? => true) }
      let(:user_b)     { double('user', :id => 14, :persisted? => true) }

      it "creates insert statements with all fields and attributes" do
        expect(Riddle::Query::Insert).to receive(:new).twice.
          with('my_index', ['id', 'name', 'created_at'], [[123, 'Foo', time]]).
          and_return(insert)

        callbacks.after_save instance
      end

      it "gets the document id for each reader" do
        expect(index).to receive(:document_id_for_key).with(13).and_return(123)
        expect(index).to receive(:document_id_for_key).with(14).and_return(123)

        callbacks.after_save instance
      end

      it "translates values for each reader" do
        expect(field).to receive(:translate).with(user_a).and_return('Foo')
        expect(field).to receive(:translate).with(user_b).and_return('Foo')

        callbacks.after_save instance
      end

      it "creates insert statements with all fields and attributes" do
        expect(Riddle::Query::Insert).to receive(:new).twice.
          with('my_index', ['id', 'name', 'created_at'], [[123, 'Foo', time]]).
          and_return(insert)

        callbacks.after_commit instance
      end

      it "gets the document id for each reader" do
        expect(index).to receive(:document_id_for_key).with(13).and_return(123)
        expect(index).to receive(:document_id_for_key).with(14).and_return(123)

        callbacks.after_commit instance
      end

      it "translates values for each reader" do
        expect(field).to receive(:translate).with(user_a).and_return('Foo')
        expect(field).to receive(:translate).with(user_b).and_return('Foo')

        callbacks.after_commit instance
      end
    end

    context 'with a block instead of a path' do
      let(:callbacks)  {
        ThinkingSphinx::RealTime::Callbacks::RealTimeCallbacks.new(
          :article
        ) { |object| object.readers }
      }
      let(:instance)   { double('instance', :id => 12,
        :readers => [user_a, user_b]) }
      let(:user_a)     { double('user', :id => 13, :persisted? => true) }
      let(:user_b)     { double('user', :id => 14, :persisted? => true) }

      it "creates insert statements with all fields and attributes" do
        expect(Riddle::Query::Insert).to receive(:new).twice.
          with('my_index', ['id', 'name', 'created_at'], [[123, 'Foo', time]]).
          and_return(insert)

        callbacks.after_save instance
      end

      it "gets the document id for each reader" do
        expect(index).to receive(:document_id_for_key).with(13).and_return(123)
        expect(index).to receive(:document_id_for_key).with(14).and_return(123)

        callbacks.after_save instance
      end

      it "translates values for each reader" do
        expect(field).to receive(:translate).with(user_a).and_return('Foo')
        expect(field).to receive(:translate).with(user_b).and_return('Foo')

        callbacks.after_save instance
      end

      it "creates insert statements with all fields and attributes" do
        expect(Riddle::Query::Insert).to receive(:new).twice.
          with('my_index', ['id', 'name', 'created_at'], [[123, 'Foo', time]]).
          and_return(insert)

        callbacks.after_commit instance
      end

      it "gets the document id for each reader" do
        expect(index).to receive(:document_id_for_key).with(13).and_return(123)
        expect(index).to receive(:document_id_for_key).with(14).and_return(123)

        callbacks.after_commit instance
      end

      it "translates values for each reader" do
        expect(field).to receive(:translate).with(user_a).and_return('Foo')
        expect(field).to receive(:translate).with(user_b).and_return('Foo')

        callbacks.after_commit instance
      end
    end
  end
end
