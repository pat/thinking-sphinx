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
  let(:stream)        { double :puts => nil }

  describe '#clear' do
    let(:plain_index) { double(:type => 'plain') }
    let(:users_index) { double(:name => 'users', :type => 'rt', :render => true,
      :path => '/path/to/my/index/users') }
    let(:parts_index) { double(:name => 'parts', :type => 'rt', :render => true,
      :path => '/path/to/my/index/parts') }

    before :each do
      allow(configuration).to receive_messages(
        :indices => [plain_index, users_index, parts_index],
        :searchd => double(:binlog_path => '/path/to/binlog')
      )

      allow(Dir).to receive(:[]).with('/path/to/my/index/users.*').
        and_return(['users.a', 'users.b'])
      allow(Dir).to receive(:[]).with('/path/to/my/index/parts.*').
        and_return(['parts.a', 'parts.b'])

      allow(FileUtils).to receive_messages :mkdir_p => true, :rm_r => true,
        :rm => true
      allow(File).to receive_messages :exists? => true
    end

    it 'finds each file for real-time indices' do
      expect(Dir).to receive(:[]).with('/path/to/my/index/users.*').
        and_return([])

      interface.clear
    end

    it "removes the directory for the binlog files" do
      expect(FileUtils).to receive(:rm_r).with('/path/to/binlog')

      interface.clear
    end

    it "removes each file for real-time indices" do
      expect(FileUtils).to receive(:rm).with('users.a')
      expect(FileUtils).to receive(:rm).with('users.b')
      expect(FileUtils).to receive(:rm).with('parts.a')
      expect(FileUtils).to receive(:rm).with('parts.b')

      interface.clear
    end

    context "with options[:index_filter]" do
      let(:interface) { ThinkingSphinx::Interfaces::RealTime.new(
        configuration, {:index_filter => 'users'}, stream
      ) }

      it "removes each file for real-time indices that match :index_filter" do
        expect(FileUtils).to receive(:rm).with('users.a')
        expect(FileUtils).to receive(:rm).with('users.b')
        expect(FileUtils).not_to receive(:rm).with('parts.a')
        expect(FileUtils).not_to receive(:rm).with('parts.b')

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

      allow(FileUtils).to receive_messages :mkdir_p => true
    end

    it 'populates each real-index' do
      expect(ThinkingSphinx::RealTime::Populator).to receive(:populate).with(users_index)
      expect(ThinkingSphinx::RealTime::Populator).to receive(:populate).with(parts_index)
      expect(ThinkingSphinx::RealTime::Populator).not_to receive(:populate).with(plain_index)

      interface.index
    end

    context "with options[:index_filter]" do
      let(:interface) { ThinkingSphinx::Interfaces::RealTime.new(
        configuration, {:index_filter => 'users'}, stream
      ) }

      it 'populates each real-index that matches :index_filter' do
        expect(ThinkingSphinx::RealTime::Populator).to receive(:populate).with(users_index)
        expect(ThinkingSphinx::RealTime::Populator).not_to receive(:populate).with(parts_index)
        expect(ThinkingSphinx::RealTime::Populator).not_to receive(:populate).with(plain_index)

        interface.index
      end
    end
  end
end
