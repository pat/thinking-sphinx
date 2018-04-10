# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ThinkingSphinx::Interfaces::SQL do
  let(:interface)     { ThinkingSphinx::Interfaces::RealTime.new(
    configuration, {}, stream
  ) }
  let(:configuration) { double 'configuration', :controller => controller,
    :render => true, :indices_location => '/path/to/indices',
    :preload_indices => true }
  let(:controller)    { double 'controller', :running? => true }
  let(:commander)     { double :call => true }
  let(:stream)        { double :puts => nil }

  before :each do
    stub_const "ThinkingSphinx::Commander", commander
  end

  describe '#clear' do
    let(:plain_index) { double(:type => 'plain') }
    let(:users_index) { double(:name => 'users', :type => 'rt', :render => true,
      :path => '/path/to/my/index/users') }
    let(:parts_index) { double(:name => 'parts', :type => 'rt', :render => true,
      :path => '/path/to/my/index/parts') }

    before :each do
      allow(configuration).to receive_messages(
        :indices => [plain_index, users_index, parts_index]
      )
    end

    it 'prepares the indices' do
      expect(commander).to receive(:call).with(
        :prepare, configuration, {}, stream
      )

      interface.clear
    end

    it 'invokes the clear command' do
      expect(commander).to receive(:call).with(
        :clear_real_time,
        configuration,
        {:indices => [users_index, parts_index]},
        stream
      )

      interface.clear
    end

    context "with options[:index_names]" do
      let(:interface) { ThinkingSphinx::Interfaces::RealTime.new(
        configuration, {:index_names => ['users']}, stream
      ) }

      it "removes each file for real-time indices that match :index_filter" do
        expect(commander).to receive(:call).with(
          :clear_real_time,
          configuration,
          {:index_names => ['users'], :indices => [users_index]},
          stream
        )

        interface.clear
      end
    end
  end

  describe '#index' do
    let(:plain_index) { double(:type => 'plain') }
    let(:users_index) { double(name: 'users', :type => 'rt') }
    let(:parts_index) { double(name: 'parts', :type => 'rt') }

    before :each do
      allow(configuration).to receive_messages(
        :indices => [plain_index, users_index, parts_index]
      )
    end

    it 'invokes the index command with real-time indices' do
      expect(commander).to receive(:call).with(
        :index_real_time,
        configuration,
        {:indices => [users_index, parts_index]},
        stream
      )

      interface.index
    end

    context "with options[:index_names]" do
      let(:interface) { ThinkingSphinx::Interfaces::RealTime.new(
        configuration, {:index_names => ['users']}, stream
      ) }

      it 'invokes the index command for matching indices' do
        expect(commander).to receive(:call).with(
          :index_real_time,
          configuration,
          {:index_names => ['users'], :indices => [users_index]},
          stream
        )

        interface.index
      end
    end
  end
end
