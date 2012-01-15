require 'spec_helper'

describe ThinkingSphinx::Search::Glaze do
  let(:object)    { double('object') }
  let(:excerpter) { double('excerpter') }
  let(:raw)       { {} }
  let(:glaze)     { ThinkingSphinx::Search::Glaze.new object, excerpter, raw }

  describe '#!=' do
    it "is true for objects that don't match" do
      (glaze != double('foo')).should be_true
    end

    it "is false when the underlying object is a match" do
      (glaze != object).should be_false
    end
  end

  describe '#distance' do
    it "returns the object's geodistance attribute by default" do
      raw['geodist'] = 123.45

      glaze.distance.should == 123.45
    end

    it "converts string geodistances to floats" do
      raw['geodist'] = '123.450'

      glaze.distance.should == 123.45
    end

    it "respects an existing distance method" do
      klass = Class.new do
        def distance
          10
        end
      end

      ThinkingSphinx::Search::Glaze.new(klass.new).distance.should == 10
    end
  end

  describe '#excerpts' do
    it "returns an excerpt glazing" do
      glaze.excerpts.class.should == ThinkingSphinx::Search::ExcerptGlaze
    end

    it "respects an existing excerpts method" do
      klass = Class.new do
        def excerpts
          :custom_excerpts
        end
      end

      ThinkingSphinx::Search::Glaze.new(klass.new).excerpts.
        should == :custom_excerpts
    end
  end

  describe '#geodist' do
    it "returns the object's geodistance attribute by default" do
      raw['geodist'] = 123.45

      glaze.geodist.should == 123.45
    end

    it "converts string geodistances to floats" do
      raw['geodist'] = '123.450'

      glaze.geodist.should == 123.45
    end

    it "respects an existing geodist method" do
      klass = Class.new do
        def geodist
          10
        end
      end

      ThinkingSphinx::Search::Glaze.new(klass.new).geodist.should == 10
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

  describe '#weight' do
    it "returns the object's weight by default" do
      raw['weight'] = 101

      glaze.weight.should == 101
    end

    it "respects an existing sphinx_attributes method" do
      klass = Class.new do
        def weight
          202
        end
      end

      ThinkingSphinx::Search::Glaze.new(klass.new).weight.should == 202
    end
  end
end
