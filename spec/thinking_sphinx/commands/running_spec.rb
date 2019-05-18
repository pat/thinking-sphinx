# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ThinkingSphinx::Commands::Running do
  let(:command)    { ThinkingSphinx::Commands::Running.new(
    configuration, {}, stream
  ) }
  let(:configuration) {
    double 'configuration', :controller => controller, :settings => {}
  }
  let(:stream)        { double :puts => nil }
  let(:controller)    { double 'controller', :running? => false }

  it 'returns true when Sphinx is running' do
    allow(controller).to receive(:running?).and_return(true)

    expect(command.call).to eq(true)
  end

  it 'returns false when Sphinx is not running' do
    expect(command.call).to eq(false)
  end

  it 'returns true if the flag is set' do
    configuration.settings['skip_running_check'] = true

    expect(command.call).to eq(true)
  end
end
