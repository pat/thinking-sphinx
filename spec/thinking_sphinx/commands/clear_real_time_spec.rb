# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ThinkingSphinx::Commands::ClearRealTime do
  let(:command)       { ThinkingSphinx::Commands::ClearRealTime.new(
    configuration, {:indices => [users_index, parts_index]}, stream
  ) }
  let(:configuration) { double 'configuration', :searchd => double(:binlog_path => '/path/to/binlog') }
  let(:stream)        { double :puts => nil }
  let(:users_index)   { double :path => '/path/to/my/index/users', :render => true }
  let(:parts_index)   { double :path => '/path/to/my/index/parts', :render => true }

  before :each do
    allow(Dir).to receive(:[]).with('/path/to/my/index/users.*').
      and_return(['users.a', 'users.b'])
    allow(Dir).to receive(:[]).with('/path/to/my/index/parts.*').
      and_return(['parts.a', 'parts.b'])

    allow(FileUtils).to receive_messages :rm_rf => true,
      :rm => true
    allow(File).to receive_messages :exist? => true
  end

  it 'finds each file for real-time indices' do
    expect(Dir).to receive(:[]).with('/path/to/my/index/users.*').
      and_return([])

    command.call
  end

  it "removes the directory for the binlog files" do
    expect(FileUtils).to receive(:rm_rf).with('/path/to/binlog')

    command.call
  end

  it "removes each file for real-time indices" do
    expect(FileUtils).to receive(:rm).with('users.a')
    expect(FileUtils).to receive(:rm).with('users.b')
    expect(FileUtils).to receive(:rm).with('parts.a')
    expect(FileUtils).to receive(:rm).with('parts.b')

    command.call
  end
end
