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

  describe '#model' do
    let(:model)  { double('model') }

    it "translates symbol references to model class" do
      ActiveSupport::Inflector.stub!(:constantize => model)

      index.model.should == model
    end

    it "memoizes the result" do
      ActiveSupport::Inflector.should_receive(:constantize).with('User').once.
        and_return(model)

      index.model
      index.model
    end
  end

  describe '#offset' do
    let(:config) { double('config', :next_offset => 4) }

    before :each do
      ThinkingSphinx::Configuration.stub!(:instance => config)
    end

    it "uses the next offset value from the configuration" do
      index.offset.should == 4
    end

    it "uses the reference to get a unique offset" do
      config.should_receive(:next_offset).with(:user).and_return(2)

      index.offset
    end
  end

  describe '#render' do
    it "interprets the provided definition" do
      index.should_receive(:interpret_definition!)

      begin
        index.render
      rescue Riddle::Configuration::ConfigurationError
        # Ignoring underlying validation error.
      end
    end
  end
end
