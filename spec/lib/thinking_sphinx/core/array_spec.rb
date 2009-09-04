require 'spec/spec_helper'

describe Array do
  describe '.===' do
    it "should return true if an instance of ThinkingSphinx::Search" do
      Array.should === ThinkingSphinx::Search.new
    end
  end
end
