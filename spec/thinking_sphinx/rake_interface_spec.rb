require 'spec_helper'

describe ThinkingSphinx::RakeInterface do
  let(:interface)     { ThinkingSphinx::RakeInterface.new }

  describe '#configure' do
    let(:command) { double 'command', :call => true }

    before :each do
      stub_const 'ThinkingSphinx::Commands::Configure', command
    end

    it 'sends the configure command' do
      expect(command).to receive(:call)

      interface.configure
    end
  end

  describe '#daemon' do
    it 'returns a daemon interface' do
      expect(interface.daemon.class).to eq(ThinkingSphinx::Interfaces::Daemon)
    end
  end

  describe '#rt' do
    it 'returns a real-time interface' do
      expect(interface.rt.class).to eq(ThinkingSphinx::Interfaces::RealTime)
    end
  end

  describe '#sql' do
    it 'returns an SQL interface' do
      expect(interface.sql.class).to eq(ThinkingSphinx::Interfaces::SQL)
    end
  end
end
