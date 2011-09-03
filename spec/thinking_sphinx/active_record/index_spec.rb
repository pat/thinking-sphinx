require 'spec_helper'

describe ThinkingSphinx::ActiveRecord::Index do
  let(:index) { ThinkingSphinx::ActiveRecord::Index.new :user }

  describe '#interpret_definition!' do
    let(:block) { double('block') }

    before :each do
      index.definition_block = block
    end

    it "interprets the definition block" do
      ThinkingSphinx::ActiveRecord::Interpreter.should_receive(:translate!).
        with(index, block)

      index.interpret_definition!
    end

    it "only interprets the definition block once" do
      ThinkingSphinx::ActiveRecord::Interpreter.should_receive(:translate!).
        once

      index.interpret_definition!
      index.interpret_definition!
    end
  end

  describe '#render' do
    it "interprets the provided definition"
  end
end
