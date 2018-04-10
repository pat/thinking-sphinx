# frozen_string_literal: true

require 'spec_helper'

describe ThinkingSphinx::RakeInterface do
  let(:interface) { ThinkingSphinx::RakeInterface.new }
  let(:commander) { double :call => nil }

  before :each do
    stub_const 'ThinkingSphinx::Commander', commander
  end

  describe '#configure' do
    it 'sends the configure command' do
      expect(commander).to receive(:call).
        with(:configure, anything, {:verbose => true})

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
