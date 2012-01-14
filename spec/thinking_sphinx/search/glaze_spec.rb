require 'spec_helper'

describe ThinkingSphinx::Search::Glaze do
  let(:object) { double('object') }
  let(:raw)    { {} }
  let(:glaze)  { ThinkingSphinx::Search::Glaze.new object, raw }

  describe '#!=' do
    it "is true for objects that don't match" do
      (glaze != double('foo')).should be_true
    end

    it "is false when the underlying object is a match" do
      (glaze != object).should be_false
    end
  end

  describe '#sphinx_attributes' do
    it "returns the object's sphinx attributes by default" do
      raw['foo'] = 24

      glaze.sphinx_attributes.should == {'foo' => 24}
    end

    it "respects an existing sphinx_attributes method" do
      klass = Class.new do
        def sphinx_attributes
          :special_attributes
        end
      end

      ThinkingSphinx::Search::Glaze.new(klass.new).sphinx_attributes.
        should == :special_attributes
    end
  end
end
