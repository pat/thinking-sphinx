# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ThinkingSphinx::Interfaces::Daemon do
  let(:configuration) { double 'configuration' }
  let(:stream)        { double 'stream', :puts => true }
  let(:commander)     { double :call => nil }
  let(:interface)     {
    ThinkingSphinx::Interfaces::Daemon.new(configuration, {}, stream)
  }

  before :each do
    stub_const 'ThinkingSphinx::Commander', commander

    allow(commander).to receive(:call).
      with(:running, configuration, {}, stream).and_return(false)
  end

  describe '#start' do
    it "starts the daemon" do
      expect(commander).to receive(:call).with(
        :start_detached, configuration, {}, stream
      )

      interface.start
    end

    it "raises an error if the daemon is already running" do
      allow(commander).to receive(:call).
        with(:running, configuration, {}, stream).and_return(true)

      expect {
        interface.start
      }.to raise_error(ThinkingSphinx::SphinxAlreadyRunning)
    end
  end

  describe '#status' do
    it "reports when the daemon is running" do
      allow(commander).to receive(:call).
        with(:running, configuration, {}, stream).and_return(true)

      expect(stream).to receive(:puts).
        with('The Sphinx daemon searchd is currently running.')

      interface.status
    end

    it "reports when the daemon is not running" do
      allow(commander).to receive(:call).
        with(:running, configuration, {}, stream).and_return(false)

      expect(stream).to receive(:puts).
        with('The Sphinx daemon searchd is not currently running.')

      interface.status
    end
  end
end
