module ThinkingSphinx
  module Panes; end
end

require 'thinking_sphinx/panes/attributes_pane'

describe ThinkingSphinx::Panes::AttributesPane do
  let(:pane)    {
    ThinkingSphinx::Panes::AttributesPane.new context, object, raw }
  let(:context) { double('context') }
  let(:object)  { double('object') }
  let(:raw)     { {} }

  describe '#sphinx_attributes' do
    it "returns the object's sphinx attributes by default" do
      raw['foo'] = 24

      pane.sphinx_attributes.should == {'foo' => 24}
    end
  end
end
