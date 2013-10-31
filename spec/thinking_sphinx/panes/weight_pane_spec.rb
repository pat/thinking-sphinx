module ThinkingSphinx
  module Panes; end
end

require 'thinking_sphinx/panes/weight_pane'

describe ThinkingSphinx::Panes::WeightPane do
  let(:pane)    { ThinkingSphinx::Panes::WeightPane.new context, object, raw }
  let(:context) { double('context') }
  let(:object)  { double('object') }
  let(:raw)     { {} }

  describe '#weight' do
    it "returns the object's weight by default" do
      raw[ThinkingSphinx::SphinxQL.weight] = 101

      pane.weight.should == 101
    end
  end
end
