require 'spec_helper'

describe ThinkingSphinx::Deltas do
  describe '.processor_for' do
    it "returns the default processor class when given true" do
      expect(ThinkingSphinx::Deltas.processor_for(true)).
        to eq(ThinkingSphinx::Deltas::DefaultDelta)
    end

    it "returns the class when given one" do
      klass = Class.new
      expect(ThinkingSphinx::Deltas.processor_for(klass)).to eq(klass)
    end

    it "instantiates a class from the name as a string" do
      expect(ThinkingSphinx::Deltas.
        processor_for('ThinkingSphinx::Deltas::DefaultDelta')).
        to eq(ThinkingSphinx::Deltas::DefaultDelta)
    end
  end

  describe '.suspend' do
    let(:config)      { double('config',
      :indices_for_references => [core_index, delta_index]) }
    let(:core_index)  { double('index', :name => 'user_core',
      :delta_processor => processor, :delta? => false) }
    let(:delta_index) { double('index', :name => 'user_core',
      :delta_processor => processor, :delta? => true) }
    let(:processor)   { double('processor', :index => true) }

    before :each do
      allow(ThinkingSphinx::Configuration).to receive_messages :instance => config
    end

    it "executes the given block" do
      variable = :foo

      ThinkingSphinx::Deltas.suspend :user do
        variable = :bar
      end

      expect(variable).to eq(:bar)
    end

    it "suspends deltas within the block" do
      ThinkingSphinx::Deltas.suspend :user do
        expect(ThinkingSphinx::Deltas).to be_suspended
      end
    end

    it "removes the suspension after the block" do
      ThinkingSphinx::Deltas.suspend :user do
        #
      end

      expect(ThinkingSphinx::Deltas).not_to be_suspended
    end

    it "processes the delta indices for the given reference" do
      expect(processor).to receive(:index).with(delta_index)

      ThinkingSphinx::Deltas.suspend :user do
        #
      end
    end

    it "does not process the core indices for the given reference" do
      expect(processor).not_to receive(:index).with(core_index)

      ThinkingSphinx::Deltas.suspend :user do
        #
      end
    end
  end
end
