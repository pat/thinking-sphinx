# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ThinkingSphinx::Commands::Merge do
  let(:command)       { ThinkingSphinx::Commands::Merge.new(
    configuration, {}, stream
  ) }
  let(:configuration) { double "configuration", :controller => controller,
    :preload_indices => nil, :render => "", :indices => [core_index_a,
      delta_index_a, rt_index, plain_index, core_index_b, delta_index_b] }
  let(:stream)        { double :puts => nil }
  let(:controller)    { double "controller", :merge => nil }
  let(:core_index_a)  { double "index", :type => "plain", :options => {:delta_processor => true}, :delta? => false, :name => "index_a_core", :model => model_a, :path => "index_a_core" }
  let(:delta_index_a) { double "index", :type => "plain", :options => {:delta_processor => true}, :delta? => true, :name => "index_a_delta", :path => "index_a_delta" }
  let(:core_index_b)  { double "index", :type => "plain", :options => {:delta_processor => true}, :delta? => false, :name => "index_b_core", :model => model_b, :path => "index_b_core" }
  let(:delta_index_b) { double "index", :type => "plain", :options => {:delta_processor => true}, :delta? => true, :name => "index_b_delta", :path => "index_b_delta" }
  let(:rt_index)      { double "index", :type => "rt", :name => "rt_index" }
  let(:plain_index)   { double "index", :type => "plain", :name => "plain_index", :options => {:delta_processor => nil} }
  let(:model_a)       { double "model", :where => where_a }
  let(:model_b)       { double "model", :where => where_b }
  let(:where_a)       { double "where", :update_all => nil }
  let(:where_b)       { double "where", :update_all => nil }

  before :each do
    allow(File).to receive(:exist?).and_return(true)
  end

  it "merges core/delta pairs" do
    expect(controller).to receive(:merge).with(
      "index_a_core", "index_a_delta",
      hash_including(:filters => {:sphinx_deleted => 0})
    )
    expect(controller).to receive(:merge).with(
      "index_b_core", "index_b_delta",
      hash_including(:filters => {:sphinx_deleted => 0})
    )

    command.call
  end

  it "unflags delta records" do
    expect(model_a).to receive(:where).with(:delta => true).and_return(where_a)
    expect(where_a).to receive(:update_all).with(:delta => false)

    expect(model_b).to receive(:where).with(:delta => true).and_return(where_b)
    expect(where_b).to receive(:update_all).with(:delta => false)

    command.call
  end

  it "does not merge if just the core does not exist" do
    allow(File).to receive(:exist?).with("index_a_core.spi").and_return(false)

    expect(controller).to_not receive(:merge).with(
      "index_a_core", "index_a_delta",
      hash_including(:filters => {:sphinx_deleted => 0})
    )
    expect(controller).to receive(:merge).with(
      "index_b_core", "index_b_delta",
      hash_including(:filters => {:sphinx_deleted => 0})
    )

    command.call
  end

  it "does not merge if just the delta does not exist" do
    allow(File).to receive(:exist?).with("index_a_delta.spi").and_return(false)

    expect(controller).to_not receive(:merge).with(
      "index_a_core", "index_a_delta",
      hash_including(:filters => {:sphinx_deleted => 0})
    )
    expect(controller).to receive(:merge).with(
      "index_b_core", "index_b_delta",
      hash_including(:filters => {:sphinx_deleted => 0})
    )

    command.call
  end

  it "ignores real-time indices" do
    expect(controller).to_not receive(:merge).with(
      "rt_index", anything, anything
    )
    expect(controller).to_not receive(:merge).with(
      anything, "rt_index", anything
    )

    command.call
  end

  it "ignores non-delta SQL indices" do
    expect(controller).to_not receive(:merge).with(
      "plain_index", anything, anything
    )
    expect(controller).to_not receive(:merge).with(
      anything, "plain_index", anything
    )

    command.call
  end
end
