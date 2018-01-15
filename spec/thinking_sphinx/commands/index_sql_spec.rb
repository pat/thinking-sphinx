# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ThinkingSphinx::Commands::IndexSQL do
  let(:command)    { ThinkingSphinx::Commands::IndexSQL.new(
    configuration, {:verbose => true}, stream
  ) }
  let(:configuration) { double 'configuration', :controller => controller }
  let(:controller)    { double 'controller', :index => true }
  let(:stream)        { double :puts => nil }

  before :each do
    allow(ThinkingSphinx).to receive_messages :before_index_hooks => []
  end

  it "calls all registered hooks" do
    called = false
    ThinkingSphinx.before_index_hooks << Proc.new { called = true }

    command.call

    expect(called).to eq(true)
  end

  it "indexes all indices verbosely" do
    expect(controller).to receive(:index).with(:verbose => true)

    command.call
  end

  it "does not index verbosely if requested" do
    command = ThinkingSphinx::Commands::IndexSQL.new(
      configuration, {:verbose => false}, stream
    )

    expect(controller).to receive(:index).with(:verbose => false)

    command.call
  end

  it "ignores a nil indices filter" do
    command = ThinkingSphinx::Commands::IndexSQL.new(
      configuration, {:verbose => false, :indices => nil}, stream
    )

    expect(controller).to receive(:index).with(:verbose => false)

    command.call
  end

  it "ignores an empty indices filter" do
    command = ThinkingSphinx::Commands::IndexSQL.new(
      configuration, {:verbose => false, :indices => []}, stream
    )

    expect(controller).to receive(:index).with(:verbose => false)

    command.call
  end

  it "uses filtered index names" do
    command = ThinkingSphinx::Commands::IndexSQL.new(
      configuration, {:verbose => false, :indices => ['foo_bar']}, stream
    )

    expect(controller).to receive(:index).with('foo_bar', :verbose => false)

    command.call
  end
end
