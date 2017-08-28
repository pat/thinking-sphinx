require 'spec_helper'

RSpec.describe ThinkingSphinx::Commands::Index do
  let(:command)    { ThinkingSphinx::Commands::Index.new(
    configuration, {:verbose => true}, stream
  ) }
  let(:configuration) { double 'configuration', :controller => controller }
  let(:controller)    { double 'controller', :index => true }
  let(:stream)        { double :puts => nil }

  it "indexes all indices verbosely" do
    expect(controller).to receive(:index).with(:verbose => true)

    command.call
  end

  it "does not index verbosely if requested" do
    command = ThinkingSphinx::Commands::Index.new(
      configuration, {:verbose => false}, stream
    )

    expect(controller).to receive(:index).with(:verbose => false)

    command.call
  end
end
