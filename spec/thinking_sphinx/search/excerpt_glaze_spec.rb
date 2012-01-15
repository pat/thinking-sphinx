require 'spec_helper'

describe ThinkingSphinx::Search::ExcerptGlaze do
  let(:glaze)     { ThinkingSphinx::Search::ExcerptGlaze.new object, excerpter }
  let(:object)    { double('object', :description => 'lots of words') }
  let(:excerpter) { double('excerpter') }

  describe '#method_missing' do
    it "uses the object's response and runs it through the excerpter" do
      excerpter.should_receive(:excerpt!).with('lots of words')

      glaze.description
    end

    it "returns the excerpted value" do
      excerpter.stub :excerpt! => 'lots of <strong>words</strong>'

      glaze.description.should == 'lots of <strong>words</strong>'
    end

    it "translates non-strings to strings before excerpting" do
      object.stub :id => 55

      excerpter.should_receive(:excerpt!).with('55')

      glaze.id
    end
  end
end
