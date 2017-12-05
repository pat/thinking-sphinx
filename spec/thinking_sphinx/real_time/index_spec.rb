# frozen_string_literal: true

require 'spec_helper'

describe ThinkingSphinx::RealTime::Index do
  let(:index)        { ThinkingSphinx::RealTime::Index.new :user }
  let(:config)       { double('config', :settings => {},
    :indices_location => 'location', :next_offset => 8) }

  before :each do
    allow(ThinkingSphinx::Configuration).to receive_messages :instance => config
  end

  describe '#attributes' do
    it "has the internal id attribute by default" do
      expect(index.attributes.collect(&:name)).to include('sphinx_internal_id')
    end

    it "has the class name attribute by default" do
      expect(index.attributes.collect(&:name)).to include('sphinx_internal_class')
    end

    it "has the internal deleted attribute by default" do
      expect(index.attributes.collect(&:name)).to include('sphinx_deleted')
    end
  end

  describe '#delta?' do
    it "always returns false" do
      expect(index).not_to be_delta
    end
  end

  describe '#document_id_for_key' do
    it "calculates the document id based on offset and number of indices" do
      allow(config).to receive_message_chain(:indices, :count).and_return(5)
      allow(config).to receive_messages :next_offset => 7

      expect(index.document_id_for_key(123)).to eq(622)
    end
  end

  describe '#fields' do
    it "has the internal class field by default" do
      expect(index.fields.collect(&:name)).to include('sphinx_internal_class_name')
    end
  end

  describe '#interpret_definition!' do
    let(:block) { double('block') }

    before :each do
      index.definition_block = block
    end

    it "interprets the definition block" do
      expect(ThinkingSphinx::RealTime::Interpreter).to receive(:translate!).
        with(index, block)

      index.interpret_definition!
    end

    it "only interprets the definition block once" do
      expect(ThinkingSphinx::RealTime::Interpreter).to receive(:translate!).
        once

      index.interpret_definition!
      index.interpret_definition!
    end
  end

  describe '#model' do
    let(:model)  { double('model') }

    it "translates symbol references to model class" do
      allow(ActiveSupport::Inflector).to receive_messages(:constantize => model)

      expect(index.model).to eq(model)
    end

    it "memoizes the result" do
      expect(ActiveSupport::Inflector).to receive(:constantize).with('User').once.
        and_return(model)

      index.model
      index.model
    end
  end

  describe '#morphology' do
    before :each do
      skip
    end

    context 'with a render' do
      it "defaults to nil" do
        begin
          index.render
        rescue Riddle::Configuration::ConfigurationError
        end

        expect(index.morphology).to be_nil
      end

      it "reads from the settings file if provided" do
        config.settings['morphology'] = 'stem_en'

        begin
          index.render
        rescue Riddle::Configuration::ConfigurationError
        end

        expect(index.morphology).to eq('stem_en')
      end
    end
  end

  describe '#name' do
    it "always uses the core suffix" do
      index = ThinkingSphinx::RealTime::Index.new :user
      expect(index.name).to eq('user_core')
    end
  end

  describe '#offset' do
    before :each do
      allow(config).to receive_messages :next_offset => 4
    end

    it "uses the next offset value from the configuration" do
      expect(index.offset).to eq(4)
    end

    it "uses the reference to get a unique offset" do
      expect(config).to receive(:next_offset).with(:user).and_return(2)

      index.offset
    end
  end

  describe '#render' do
    before :each do
      allow(FileUtils).to receive_messages :mkdir_p => true
    end

    it "interprets the provided definition" do
      expect(index).to receive(:interpret_definition!).at_least(:once)

      begin
        index.render
      rescue Riddle::Configuration::ConfigurationError
        # Ignoring underlying validation error.
      end
    end
  end

  describe '#scope' do
    let(:model)  { double('model') }

    it "returns the model by default" do
      allow(ActiveSupport::Inflector).to receive_messages(:constantize => model)

      expect(index.scope).to eq(model)
    end

    it "returns the evaluated scope if provided" do
      index.scope = lambda { :foo }

      expect(index.scope).to eq(:foo)
    end
  end

  describe '#unique_attribute_names' do
    it "returns all attribute names" do
      expect(index.unique_attribute_names).to eq([
        'sphinx_internal_id', 'sphinx_internal_class', 'sphinx_deleted'
      ])
    end
  end
end
