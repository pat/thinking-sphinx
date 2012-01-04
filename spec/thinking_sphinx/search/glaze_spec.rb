require 'spec_helper'

describe ThinkingSphinx::Search::Glaze do
  let(:object) { double('object') }
  let(:glaze)  { ThinkingSphinx::Search::Glaze.new object }

  describe '#!=' do
    it "is true for objects that don't match" do
      (glaze != double('foo')).should be_true
    end

    it "is false when the underlying object is a match" do
      (glaze != object).should be_false
    end
  end
end
