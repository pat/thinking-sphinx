# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ThinkingSphinx::Commands::StartDetached do
  let(:command)    {
    ThinkingSphinx::Commands::StartDetached.new(configuration, {}, stream)
  }
  let(:configuration) {
    double 'configuration', :controller => controller, :settings => {}
  }
  let(:controller)    { double 'controller', :start => result, :pid => 101 }
  let(:result)        { double 'result', :command => 'start', :status => 1,
    :output => '' }
  let(:stream)        { double :puts => nil }

  before :each do
    allow(controller).to receive(:running?).and_return(true)
    allow(configuration).to receive_messages(
      :indices_location => 'my/index/files',
      :searchd          => double(:log => '/path/to/log')
    )
    allow(command).to receive(:exit).and_return(true)

    allow(FileUtils).to receive_messages :mkdir_p => true
  end

  it "creates the index files directory" do
    expect(FileUtils).to receive(:mkdir_p).with('my/index/files')

    command.call
  end

  it "skips directory creation if flag is set" do
    configuration.settings['skip_directory_creation'] = true

    expect(FileUtils).to_not receive(:mkdir_p)

    command.call
  end

  it "starts the daemon" do
    expect(controller).to receive(:start)

    command.call
  end

  it "prints a success message if the daemon has started" do
    allow(controller).to receive(:running?).and_return(true)

    expect(stream).to receive(:puts).
      with('Started searchd successfully (pid: 101).')

    command.call
  end

  it "prints a failure message if the daemon does not start" do
    allow(controller).to receive(:running?).and_return(false)
    allow(command).to receive(:exit)

    expect(stream).to receive(:puts) do |string|
      expect(string).to match('The Sphinx start command failed')
    end

    command.call
  end
end
