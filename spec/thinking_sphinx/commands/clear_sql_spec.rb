# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ThinkingSphinx::Commands::ClearSQL do
  let(:command)       { ThinkingSphinx::Commands::ClearSQL.new(
    configuration, {:indices => [users_index, parts_index]}, stream
  ) }
  let(:configuration) { double 'configuration', :preload_indices => true,
    :render => true, :indices => [users_index, parts_index],
    :indices_location => '/path/to/indices' }
  let(:stream)        { double :puts => nil }

  let(:users_index) { double(:name => 'users', :type => 'plain',
    :render => true, :path => '/path/to/my/index/users') }
  let(:parts_index) { double(:name => 'users', :type => 'plain',
    :render => true, :path => '/path/to/my/index/parts') }

  before :each do
    allow(Dir).to receive(:[]).with('/path/to/my/index/users.*').
      and_return(['users.a', 'users.b'])
    allow(Dir).to receive(:[]).with('/path/to/my/index/parts.*').
      and_return(['parts.a', 'parts.b'])
    allow(Dir).to receive(:[]).with('/path/to/indices/ts-*.tmp').
      and_return(['/path/to/indices/ts-foo.tmp'])

    allow(FileUtils).to receive_messages :rm_r => true, :rm => true
    allow(File).to receive_messages :exist? => true
  end

  it 'finds each file for sql-backed indices' do
    expect(Dir).to receive(:[]).with('/path/to/my/index/users.*').
      and_return([])

    command.call
  end

  it "removes each file for real-time indices" do
    expect(FileUtils).to receive(:rm).with('users.a')
    expect(FileUtils).to receive(:rm).with('users.b')
    expect(FileUtils).to receive(:rm).with('parts.a')
    expect(FileUtils).to receive(:rm).with('parts.b')

    command.call
  end

  it "removes any indexing guard files" do
    expect(FileUtils).to receive(:rm_r).with(["/path/to/indices/ts-foo.tmp"])

    command.call
  end
end
