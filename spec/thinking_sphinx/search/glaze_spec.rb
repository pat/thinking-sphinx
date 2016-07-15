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
      expect(glaze != double('foo')).to be_truthy
    end

    it "is false when the underlying object is a match" do
      expect(glaze != object).to be_falsey
    end
  end

  describe '#method_missing' do
    let(:glaze)    {
      ThinkingSphinx::Search::Glaze.new context, object, raw, [klass, klass] }
    let(:klass)    { double('pane class') }
    let(:pane_one) { double('pane one', :foo => 'one') }
    let(:pane_two) { double('pane two', :foo => 'two', :bar => 'two') }

    before :each do
      allow(klass).to receive(:new).and_return(pane_one, pane_two)
    end

    it "respects objects existing methods" do
      allow(object).to receive_messages :foo => 'original'

      expect(glaze.foo).to eq('original')
    end

    it "uses the first pane that responds to the method" do
      expect(glaze.foo).to eq('one')
      expect(glaze.bar).to eq('two')
    end

    it "raises the method missing error otherwise" do
      allow(object).to receive_messages :respond_to? => false
      allow(object).to receive(:baz).and_raise(NoMethodError)

      expect { glaze.baz }.to raise_error(NoMethodError)
    end
  end

  describe '#respond_to?' do
    it "responds to underlying object methods" do
      allow(object).to receive_messages :foo => true

      expect(glaze.respond_to?(:foo)).to be_truthy
    end

    it "responds to underlying pane methods" do
      pane  = double('Pane Class', :new => double('pane', :bar => true))
      glaze = ThinkingSphinx::Search::Glaze.new context, object, raw, [pane]

      expect(glaze.respond_to?(:bar)).to be_truthy
    end

    it "does not to respond to methods that don't exist" do
      expect(glaze.respond_to?(:something)).to be_falsey
    end
  end

  describe '#unglazed' do
    it "returns the original object" do
      expect(glaze.unglazed).to eq(object)
    end
  end
end
