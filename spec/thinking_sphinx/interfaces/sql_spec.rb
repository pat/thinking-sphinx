# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ThinkingSphinx::Interfaces::SQL do
  let(:interface)     { ThinkingSphinx::Interfaces::SQL.new(
    configuration, {:verbose => true}, stream
  ) }
  let(:commander) { double :call => true }
  let(:configuration) { double 'configuration', :preload_indices => true,
    :render => true, :indices => [double(:index, :type => 'plain')] }
  let(:stream)        { double :puts => nil }

  before :each do
    stub_const 'ThinkingSphinx::Commander', commander
  end

  describe '#clear' do
    let(:users_index) { double(:type => 'plain') }
    let(:parts_index) { double(:type => 'plain') }
    let(:rt_index)    { double(:type => 'rt') }

    before :each do
      allow(configuration).to receive(:indices).
        and_return([users_index, parts_index, rt_index])
    end

    it "invokes the clear_sql command" do
      expect(commander).to receive(:call).with(
        :clear_sql,
        configuration,
        {:verbose => true, :indices => [users_index, parts_index]},
        stream
      )

      interface.clear
    end
  end

  describe '#index' do
    it "invokes the prepare command" do
      expect(commander).to receive(:call).with(
        :prepare, configuration, {:verbose => true}, stream
      )

      interface.index
    end

    it "renders the configuration to a file by default" do
      expect(commander).to receive(:call).with(
        :configure, configuration, {:verbose => true}, stream
      )

      interface.index
    end

    it "does not render the configuration if requested" do
      expect(commander).not_to receive(:call).with(
        :configure, configuration, {:verbose => true}, stream
      )

      interface.index false
    end

    it "executes the index command" do
      expect(commander).to receive(:call).with(
        :index_sql, configuration, {:verbose => true, :indices => nil}, stream
      )

      interface.index
    end

    context "with options[:index_names]" do
      let(:users_index) { double(:name => 'users', :type => 'plain') }
      let(:parts_index) { double(:name => 'parts', :type => 'plain') }
      let(:rt_index)    { double(:type => 'rt') }
      let(:interface)   { ThinkingSphinx::Interfaces::SQL.new(
        configuration, {:index_names => ['users']}, stream
      ) }

      before :each do
        allow(configuration).to receive(:indices).
          and_return([users_index, parts_index, rt_index])
      end

      it 'invokes the index command for matching indices' do
        expect(commander).to receive(:call).with(
          :index_sql,
          configuration,
          {:index_names => ['users'], :indices => ['users']},
          stream
        )

        interface.index
      end
    end
  end
end
