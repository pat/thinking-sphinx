require 'spec_helper'

RSpec.describe ThinkingSphinx::RealTime::Transcriber do
  let(:subject)    { ThinkingSphinx::RealTime::Transcriber.new index }
  let(:index)      { double 'index', :name => 'foo_core', :conditions => [],
    :fields => [double(:name => 'field_a'), double(:name => 'field_b')],
    :attributes => [double(:name => 'attr_a'), double(:name => 'attr_b')] }
  let(:insert)     { double :replace! => replace }
  let(:replace)    { double :to_sql => 'REPLACE QUERY' }
  let(:connection) { double :execute => true }
  let(:instance_a) { double :id => 48, :persisted? => true }
  let(:instance_b) { double :id => 49, :persisted? => true }
  let(:properties_a) { double }
  let(:properties_b) { double }

  before :each do
    allow(Riddle::Query::Insert).to receive(:new).and_return(insert)
    allow(ThinkingSphinx::Connection).to receive(:take).and_yield(connection)
    allow(ThinkingSphinx::RealTime::TranscribeInstance).to receive(:call).
      with(instance_a, index, anything).and_return(properties_a)
    allow(ThinkingSphinx::RealTime::TranscribeInstance).to receive(:call).
      with(instance_b, index, anything).and_return(properties_b)
  end

  it "generates a SphinxQL command" do
    expect(Riddle::Query::Insert).to receive(:new).with(
      'foo_core',
      ['id', 'field_a', 'field_b', 'attr_a', 'attr_b'],
      [properties_a, properties_b]
    )

    subject.copy instance_a, instance_b
  end

  it "executes the SphinxQL command" do
    expect(connection).to receive(:execute).with('REPLACE QUERY')

    subject.copy instance_a, instance_b
  end

  it "skips instances that aren't in the database" do
    allow(instance_a).to receive(:persisted?).and_return(false)

    expect(Riddle::Query::Insert).to receive(:new).with(
      'foo_core',
      ['id', 'field_a', 'field_b', 'attr_a', 'attr_b'],
      [properties_b]
    )

    subject.copy instance_a, instance_b
  end

  it "skips instances that fail a symbol condition" do
    index.conditions << :ok?
    allow(instance_a).to receive(:ok?).and_return(true)
    allow(instance_b).to receive(:ok?).and_return(false)

    expect(Riddle::Query::Insert).to receive(:new).with(
      'foo_core',
      ['id', 'field_a', 'field_b', 'attr_a', 'attr_b'],
      [properties_a]
    )

    subject.copy instance_a, instance_b
  end

  it "skips instances that fail a Proc condition" do
    index.conditions << Proc.new { |instance| instance.ok? }
    allow(instance_a).to receive(:ok?).and_return(true)
    allow(instance_b).to receive(:ok?).and_return(false)

    expect(Riddle::Query::Insert).to receive(:new).with(
      'foo_core',
      ['id', 'field_a', 'field_b', 'attr_a', 'attr_b'],
      [properties_a]
    )

    subject.copy instance_a, instance_b
  end

  it "skips instances that throw an error while transcribing values" do
    error = ThinkingSphinx::TranscriptionError.new
    error.instance = instance_a
    error.inner_exception = StandardError.new

    allow(ThinkingSphinx::RealTime::TranscribeInstance).to receive(:call).
      with(instance_a, index, anything).
      and_raise(error)
    allow(ThinkingSphinx.output).to receive(:puts).and_return(nil)

    expect(Riddle::Query::Insert).to receive(:new).with(
      'foo_core',
      ['id', 'field_a', 'field_b', 'attr_a', 'attr_b'],
      [properties_b]
    )

    subject.copy instance_a, instance_b
  end
end
