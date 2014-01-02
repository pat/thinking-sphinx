module ThinkingSphinx
  class Search; end
end

require 'thinking_sphinx/search/glaze'

describe ThinkingSphinx::Search::Glaze do
  let(:glaze)   { ThinkingSphinx::Search::Glaze.new context, object, raw, [] }
  let(:object)  { double('object') }
  let(:raw)     { {} }
  let(:context) { {} }

  describe '#!=' do
    it "is true for objects that don't match" do
      (glaze != double('foo')).should be_true
    end

    it "is false when the underlying object is a match" do
      (glaze != object).should be_false
    end
  end

  describe '#method_missing' do
    let(:glaze)    {
      ThinkingSphinx::Search::Glaze.new context, object, raw, [klass, klass] }
    let(:klass)    { double('pane class') }
    let(:pane_one) { double('pane one', :foo => 'one') }
    let(:pane_two) { double('pane two', :foo => 'two', :bar => 'two') }

    before :each do
      klass.stub(:new).and_return(pane_one, pane_two)
    end

    it "respects objects existing methods" do
      object.stub :foo => 'original'

      glaze.foo.should == 'original'
    end

    it "uses the first pane that responds to the method" do
      glaze.foo.should == 'one'
      glaze.bar.should == 'two'
    end

    it "raises the method missing error otherwise" do
      object.stub :respond_to? => false
      object.stub(:baz).and_raise(NoMethodError)

      lambda { glaze.baz }.should raise_error(NoMethodError)
    end
  end

  describe '#respond_to?' do
    it "responds to underlying object methods" do
      object.stub :foo => true

      glaze.respond_to?(:foo).should be_true
    end

    it "responds to underlying pane methods" do
      pane  = double('Pane Class', :new => double('pane', :bar => true))
      glaze = ThinkingSphinx::Search::Glaze.new context, object, raw, [pane]

      glaze.respond_to?(:bar).should be_true
    end

    it "does not to respond to methods that don't exist" do
      glaze.respond_to?(:something).should be_false
    end
  end

  describe '#unglazed' do
    it "returns the original object" do
      glaze.unglazed.should == object
    end
  end
end
