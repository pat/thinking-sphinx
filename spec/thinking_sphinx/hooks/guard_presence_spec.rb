# frozen_string_literal: true

require "spec_helper"

RSpec.describe ThinkingSphinx::Hooks::GuardPresence do
  let(:subject) do
    ThinkingSphinx::Hooks::GuardPresence.new configuration, stream
  end
  let(:configuration) { double "configuration", :indices_location => "/path" }
  let(:stream)        { double "stream", :puts => nil }

  describe "#call" do
    it "outputs nothing if no guard files exist" do
      allow(Dir).to receive(:[]).with('/path/ts-*.tmp').and_return([])

      expect(stream).not_to receive(:puts)

      subject.call
    end

    it "outputs a warning if a guard file exists" do
      allow(Dir).to receive(:[]).with('/path/ts-*.tmp').
        and_return(['/path/ts-foo.tmp'])

      expect(stream).to receive(:puts)

      subject.call
    end
  end
end
