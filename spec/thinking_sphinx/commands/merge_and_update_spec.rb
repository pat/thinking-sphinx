# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ThinkingSphinx::Commands::MergeAndUpdate do
  let(:command)       { ThinkingSphinx::Commands::MergeAndUpdate.new(
    configuration, {}, stream
  ) }
  let(:configuration) { double "configuration", :preload_indices => nil,
    :render => "", :indices => [core_index_a, delta_index_a, rt_index,
      plain_index, core_index_b, delta_index_b] }
  let(:stream)        { double :puts => nil }
  let(:commander)     { double :call => true }
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
    stub_const 'ThinkingSphinx::Commander', commander
  end

  it "merges core/delta pairs" do
    expect(commander).to receive(:call).with(
      :merge, configuration, hash_including(
        :core_index  => core_index_a,
        :delta_index => delta_index_a,
        :filters => {:sphinx_deleted => 0}
      ), stream
    )
    expect(commander).to receive(:call).with(
      :merge, configuration, hash_including(
        :core_index  => core_index_b,
        :delta_index => delta_index_b,
        :filters => {:sphinx_deleted => 0}
      ), stream
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

  it "ignores real-time indices" do
    expect(commander).to_not receive(:call).with(
      :merge, configuration, hash_including(:core_index => rt_index), stream
    )
    expect(commander).to_not receive(:call).with(
      :merge, configuration, hash_including(:delta_index => rt_index), stream
    )

    command.call
  end

  it "ignores non-delta SQL indices" do
    expect(commander).to_not receive(:call).with(
      :merge, configuration, hash_including(:core_index => plain_index),
      stream
    )
    expect(commander).to_not receive(:call).with(
      :merge, configuration, hash_including(:delta_index => plain_index),
      stream
    )

    command.call
  end

  context "with index name filter" do
    let(:command) { ThinkingSphinx::Commands::MergeAndUpdate.new(
      configuration, {:index_names => ["index_a"]}, stream
    ) }

    it "only processes matching indices" do
      expect(commander).to receive(:call).with(
        :merge, configuration, hash_including(
          :core_index  => core_index_a,
          :delta_index => delta_index_a,
          :filters => {:sphinx_deleted => 0}
        ), stream
      )
      expect(commander).to_not receive(:call).with(
        :merge, configuration, hash_including(
          :core_index  => core_index_b,
          :delta_index => delta_index_b,
          :filters => {:sphinx_deleted => 0}
        ), stream
      )

      command.call
    end
  end
end
