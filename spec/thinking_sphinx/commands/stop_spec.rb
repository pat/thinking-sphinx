# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ThinkingSphinx::Commands::Stop do
  let(:command)    {
    ThinkingSphinx::Commands::Stop.new(configuration, {}, stream)
  }
  let(:configuration) { double 'configuration', :controller => controller }
  let(:controller)    { double 'controller', :stop => true, :pid => 101 }
  let(:stream)        { double :puts => nil }
  let(:commander)     { double :call => nil }

  before :each do
    stub_const 'ThinkingSphinx::Commander', commander

    allow(commander).to receive(:call).
      with(:running, configuration, {}, stream).and_return(true, true, false)
  end

  it "prints a message if the daemon is not already running" do
    allow(commander).to receive(:call).
      with(:running, configuration, {}, stream).and_return(false)

    expect(stream).to receive(:puts).with('searchd is not currently running.').
      and_return(nil)
    expect(stream).to_not receive(:puts).
      with('"Stopped searchd daemon (pid: ).')

    command.call
  end

  it "does not try to stop the daemon if it's not running" do
    allow(commander).to receive(:call).
      with(:running, configuration, {}, stream).and_return(false)

    expect(controller).to_not receive(:stop)

    command.call
  end

  it "stops the daemon" do
    expect(controller).to receive(:stop)

    command.call
  end

  it "prints a message informing the daemon has stopped" do
    expect(stream).to receive(:puts).with('Stopped searchd daemon (pid: 101).')

    command.call
  end

  it "should retry stopping the daemon until it stops" do
    allow(commander).to receive(:call).
      with(:running, configuration, {}, stream).
      and_return(true, true, true, false)

    expect(controller).to receive(:stop).twice

    command.call
  end
end
