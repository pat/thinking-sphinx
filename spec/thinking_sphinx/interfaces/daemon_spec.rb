require 'spec_helper'

RSpec.describe ThinkingSphinx::Interfaces::Daemon do
  let(:configuration) { double 'configuration', :controller => controller }
  let(:controller)    { double 'controller', :running? => false }
  let(:stream)        { double 'stream', :puts => true }
  let(:interface)     {
    ThinkingSphinx::Interfaces::Daemon.new(configuration, {}, stream)
  }

  describe '#start' do
    let(:command) { double 'command', :call => true }

    before :each do
      stub_const 'ThinkingSphinx::Commands::StartDetached', command
    end

    it "starts the daemon" do
      expect(command).to receive(:call)

      interface.start
    end

    it "raises an error if the daemon is already running" do
      allow(controller).to receive_messages :running? => true

      expect {
        interface.start
      }.to raise_error(ThinkingSphinx::SphinxAlreadyRunning)
    end
  end

  describe '#status' do
    it "reports when the daemon is running" do
      allow(controller).to receive_messages :running? => true

      expect(stream).to receive(:puts).
        with('The Sphinx daemon searchd is currently running.')

      interface.status
    end

    it "reports when the daemon is not running" do
      allow(controller).to receive_messages :running? => false

      expect(stream).to receive(:puts).
        with('The Sphinx daemon searchd is not currently running.')

      interface.status
    end
  end
end
