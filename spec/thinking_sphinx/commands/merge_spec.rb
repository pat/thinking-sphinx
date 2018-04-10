# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ThinkingSphinx::Commands::Merge do
  let(:command)       { ThinkingSphinx::Commands::Merge.new(
    configuration, {:core_index => core_index, :delta_index => delta_index,
      :filters => {:sphinx_deleted => 0}}, stream
  ) }
  let(:configuration) { double "configuration", :controller => controller }
  let(:stream)        { double :puts => nil }
  let(:controller)    { double "controller", :merge => nil }
  let(:core_index)    { double "index", :path => "index_a_core",
    :name => "index_a_core" }
  let(:delta_index)   { double "index", :path => "index_a_delta",
    :name => "index_a_delta" }

  before :each do
    allow(File).to receive(:exist?).and_return(true)
  end

  it "merges core/delta pairs" do
    expect(controller).to receive(:merge).with(
      "index_a_core",
      "index_a_delta",
      :filters => {:sphinx_deleted => 0},
      :verbose => nil
    )

    command.call
  end

  it "does not merge if just the core does not exist" do
    allow(File).to receive(:exist?).with("index_a_core.spi").and_return(false)

    expect(controller).to_not receive(:merge)

    command.call
  end

  it "does not merge if just the delta does not exist" do
    allow(File).to receive(:exist?).with("index_a_delta.spi").and_return(false)

    expect(controller).to_not receive(:merge)

    command.call
  end
end
