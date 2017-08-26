require 'spec_helper'

RSpec.describe ThinkingSphinx::Commands::Configure do
  let(:command)    { ThinkingSphinx::Commands::Configure.new(
    configuration, {}, stream
  ) }
  let(:configuration) { double 'configuration' }
  let(:stream)        { double :puts => nil }

  before :each do
    allow(configuration).to receive_messages(
      :configuration_file => '/path/to/foo.conf',
      :render_to_file     => true
    )
  end

  it "renders the configuration to a file" do
    expect(configuration).to receive(:render_to_file)

    command.call
  end

  it "prints a message stating the file is being generated" do
    expect(stream).to receive(:puts).
      with('Generating configuration to /path/to/foo.conf')

    command.call
  end
end
