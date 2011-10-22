require 'spec_helper'

describe ThinkingSphinx::Deltas do
  describe '.processor_for' do
    it "returns the default processor class when given true" do
      ThinkingSphinx::Deltas.processor_for(true).
        should == ThinkingSphinx::Deltas::DefaultDelta
    end
  end
end
