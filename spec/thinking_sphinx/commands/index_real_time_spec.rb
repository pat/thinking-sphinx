# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ThinkingSphinx::Commands::IndexRealTime do
  let(:command)       { ThinkingSphinx::Commands::IndexRealTime.new(
    configuration, {:indices => [users_index, parts_index]}, stream
  ) }
  let(:configuration) { double 'configuration', :controller => controller }
  let(:controller)    { double 'controller', :rotate => nil }
  let(:stream)        { double :puts => nil }
  let(:users_index)   { double(name: 'users') }
  let(:parts_index)   { double(name: 'parts') }

  before :each do
    allow(ThinkingSphinx::RealTime::Populator).to receive(:populate)
  end

  it 'populates each real-index' do
    expect(ThinkingSphinx::RealTime::Populator).to receive(:populate).
      with(users_index)
    expect(ThinkingSphinx::RealTime::Populator).to receive(:populate).
      with(parts_index)

    command.call
  end

  it "rotates the daemon for each index" do
    expect(controller).to receive(:rotate).twice

    command.call
  end
end
