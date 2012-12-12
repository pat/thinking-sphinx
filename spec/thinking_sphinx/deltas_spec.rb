require 'spec_helper'

describe ThinkingSphinx::Deltas do
  describe '.processor_for' do
    it "returns the default processor class when given true" do
      ThinkingSphinx::Deltas.processor_for(true).
        should == ThinkingSphinx::Deltas::DefaultDelta
    end

    it "returns the class when given one" do
      klass = Class.new
      ThinkingSphinx::Deltas.processor_for(klass).should == klass
    end
    
    it "instantiates a class from the name as a string" do
      ThinkingSphinx::Deltas.
        processor_for('ThinkingSphinx::Deltas::DefaultDelta').
        should == ThinkingSphinx::Deltas::DefaultDelta
    end
  end

  describe '.suspend' do
    let(:config)     { double('config', :indices_for_references => [index]) }
    let(:index)      { double('index', :name => 'user_core',
      :delta_processor => processor) }
    let(:processor)  { double('processor', :index => true) }

    before :each do
      ThinkingSphinx::Configuration.stub :instance => config
    end

    it "executes the given block" do
      variable = :foo

      ThinkingSphinx::Deltas.suspend :user do
        variable = :bar
      end

      variable.should == :bar
    end

    it "suspends deltas within the block" do
      ThinkingSphinx::Deltas.suspend :user do
        ThinkingSphinx::Deltas.should be_suspended
      end
    end

    it "removes the suspension after the block" do
      ThinkingSphinx::Deltas.suspend :user do
        #
      end

      ThinkingSphinx::Deltas.should_not be_suspended
    end

    it "processes the delta indices for the given reference" do
      processor.should_receive(:index).with(index)

      ThinkingSphinx::Deltas.suspend :user do
        #
      end
    end
  end
end
