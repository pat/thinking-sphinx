require 'spec_helper'

describe ThinkingSphinx::Scopes do
  let(:model) {
    Class.new do
      include ThinkingSphinx::Scopes

      def self.search(query = nil, options = {})
        ThinkingSphinx::Search.new(query, options)
      end
    end
  }

  describe '#method_missing' do
    before :each do
      model.sphinx_scopes[:foo] = Proc.new { {:with => {:foo => :bar}} }
    end

    it "creates new search" do
      expect(model.foo.class).to eq(ThinkingSphinx::Search)
    end

    it "passes block result to constructor" do
      expect(model.foo.options[:with]).to eq({:foo => :bar})
    end

    it "passes non-scopes through to the standard method error call" do
      expect { model.bar }.to raise_error(NoMethodError)
    end
  end

  describe '#sphinx_scope' do
    it "saves the given block with a name" do
      model.sphinx_scope(:foo) { 27 }
      expect(model.sphinx_scopes[:foo].call).to eq(27)
    end
  end

  describe '#default_sphinx_scope' do
    it "gets and sets the default scope depending on the argument" do
      model.default_sphinx_scope :foo
      expect(model.default_sphinx_scope).to eq(:foo)
    end
  end
end
