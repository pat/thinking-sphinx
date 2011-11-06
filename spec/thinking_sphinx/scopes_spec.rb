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
      model.foo.class.should == ThinkingSphinx::Search
    end

    it "passes block result to constructor" do
      model.foo.options[:with].should == {:foo => :bar}
    end

    it "passes non-scopes through to the standard method error call" do
      lambda { model.bar }.should raise_error(NoMethodError)
    end
  end

  describe '#sphinx_scope' do
    it "saves the given block with a name" do
      model.sphinx_scope(:foo) { 27 }
      model.sphinx_scopes[:foo].call.should == 27
    end
  end
end
