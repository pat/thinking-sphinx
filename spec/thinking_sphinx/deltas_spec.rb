require 'spec_helper'

describe ThinkingSphinx::Deltas do
  describe '.processor_for' do
    it "returns the default processor class when given true" do
      ThinkingSphinx::Deltas.processor_for(true).
        should == ThinkingSphinx::Deltas::DefaultDelta
    end

    it "returns the class when given one" do
      klass = Class.new
      ThinkingSphinx::Deltas.processor_for(klass).should == klass
    end
  end
end
