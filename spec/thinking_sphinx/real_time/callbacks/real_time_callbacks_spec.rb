require 'spec_helper'

describe ThinkingSphinx::RealTime::Callbacks::RealTimeCallbacks do
  let(:callbacks)  {
    ThinkingSphinx::RealTime::Callbacks::RealTimeCallbacks.new instance
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

  describe '.after_save' do
    let(:callbacks) { double('callbacks', :after_save => nil) }

    before :each do
      ThinkingSphinx::RealTime::Callbacks::RealTimeCallbacks.
        stub :new => callbacks
    end

    it "builds an object from the instance" do
      ThinkingSphinx::RealTime::Callbacks::RealTimeCallbacks.
        should_receive(:new).with(instance).and_return(callbacks)

      ThinkingSphinx::RealTime::Callbacks::RealTimeCallbacks.
        after_save(instance)
    end

    it "invokes after_save on the object" do
      callbacks.should_receive(:after_save)

      ThinkingSphinx::RealTime::Callbacks::RealTimeCallbacks.
        after_save(instance)
    end
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

      callbacks.after_save
    end

    it "switches the insert to a replace statement" do
      insert.should_receive(:replace!).and_return(insert)

      callbacks.after_save
    end

    it "sends the insert through to the server" do
      connection.should_receive(:execute).with('REPLACE INTO my_index')

      callbacks.after_save
    end
  end
end
