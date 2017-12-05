# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ThinkingSphinx::Interfaces::SQL do
  let(:interface)     { ThinkingSphinx::Interfaces::SQL.new(
    configuration, {:verbose => true}, stream
  ) }
  let(:configuration) { double 'configuration', :preload_indices => true,
    :render => true, :indices => [double(:index, :type => 'plain')],
    :indices_location   => '/path/to/indices' }
  let(:stream)        { double :puts => nil }

  describe '#clear' do
    let(:users_index) { double(:name => 'users', :type => 'plain',
      :render => true, :path => '/path/to/my/index/users') }
    let(:parts_index) { double(:name => 'users', :type => 'plain',
      :render => true, :path => '/path/to/my/index/parts') }
    let(:rt_index)    { double(:type => 'rt') }

    before :each do
      allow(configuration).to receive_messages(
        :indices => [users_index, parts_index, rt_index]
      )

      allow(Dir).to receive(:[]).with('/path/to/my/index/users.*').
        and_return(['users.a', 'users.b'])
      allow(Dir).to receive(:[]).with('/path/to/my/index/parts.*').
        and_return(['parts.a', 'parts.b'])
      allow(Dir).to receive(:[]).with('/path/to/indices/ts-*.tmp').
        and_return(['/path/to/indices/ts-foo.tmp'])

      allow(FileUtils).to receive_messages :mkdir_p => true, :rm_r => true,
        :rm => true
      allow(File).to receive_messages :exists? => true
    end

    it 'finds each file for sql-backed indices' do
      expect(Dir).to receive(:[]).with('/path/to/my/index/users.*').
        and_return([])

      interface.clear
    end

    it "removes each file for real-time indices" do
      expect(FileUtils).to receive(:rm).with('users.a')
      expect(FileUtils).to receive(:rm).with('users.b')
      expect(FileUtils).to receive(:rm).with('parts.a')
      expect(FileUtils).to receive(:rm).with('parts.b')

      interface.clear
    end

    it "removes any indexing guard files" do
      expect(FileUtils).to receive(:rm_r).with(["/path/to/indices/ts-foo.tmp"])

      interface.clear
    end
  end

  describe '#index' do
    let(:index_command)     { double :call => true }
    let(:configure_command) { double :call => true }

    before :each do
      stub_const 'ThinkingSphinx::Commands::Index', index_command
      stub_const 'ThinkingSphinx::Commands::Configure', configure_command

      allow(ThinkingSphinx).to receive_messages :before_index_hooks => []
      allow(FileUtils).to receive_messages :mkdir_p => true
    end

    it "renders the configuration to a file by default" do
      expect(configure_command).to receive(:call)

      interface.index
    end

    it "does not render the configuration if requested" do
      expect(configure_command).not_to receive(:call)

      interface.index false
    end

    it "creates the directory for the index files" do
      expect(FileUtils).to receive(:mkdir_p).with('/path/to/indices')

      interface.index
    end

    it "calls all registered hooks" do
      called = false
      ThinkingSphinx.before_index_hooks << Proc.new { called = true }

      interface.index

      expect(called).to be_truthy
    end

    it "executes the index command" do
      expect(index_command).to receive(:call).with(
        configuration, {:verbose => true}, stream
      )

      interface.index
    end
  end
end
