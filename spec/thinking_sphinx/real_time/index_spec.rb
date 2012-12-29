require 'spec_helper'

describe ThinkingSphinx::RealTime::Index do
  let(:index)        { ThinkingSphinx::RealTime::Index.new :user }
  let(:indices_path) { double('indices path', :join => '') }
  let(:config)       { double('config', :settings => {},
    :indices_location => indices_path, :next_offset => 8) }

  before :each do
    ThinkingSphinx::Configuration.stub :instance => config
  end

  describe '#attributes' do
    it "has the internal id attribute by default" do
      index.attributes.collect(&:name).should include('sphinx_internal_id')
    end

    it "has the class name attribute by default" do
      index.attributes.collect(&:name).should include('sphinx_internal_class')
    end

    it "has the internal deleted attribute by default" do
      index.attributes.collect(&:name).should include('sphinx_deleted')
    end
  end

  describe '#delta?' do
    it "always returns false" do
      index.should_not be_delta
    end
  end

  describe '#document_id_for_key' do
    it "calculates the document id based on offset and number of indices" do
      config.stub_chain(:indices, :count).and_return(5)
      config.stub :next_offset => 7

      index.document_id_for_key(123).should == 622
    end
  end

  describe '#fields' do
    it "has the internal class field by default" do
      index.fields.collect(&:name).should include('sphinx_internal_class_name')
    end
  end

  describe '#interpret_definition!' do
    let(:block) { double('block') }

    before :each do
      index.definition_block = block
    end

    it "interprets the definition block" do
      ThinkingSphinx::RealTime::Interpreter.should_receive(:translate!).
        with(index, block)

      index.interpret_definition!
    end

    it "only interprets the definition block once" do
      ThinkingSphinx::RealTime::Interpreter.should_receive(:translate!).
        once

      index.interpret_definition!
      index.interpret_definition!
    end
  end

  describe '#model' do
    let(:model)  { double('model') }

    it "translates symbol references to model class" do
      ActiveSupport::Inflector.stub(:constantize => model)

      index.model.should == model
    end

    it "memoizes the result" do
      ActiveSupport::Inflector.should_receive(:constantize).with('User').once.
        and_return(model)

      index.model
      index.model
    end
  end

  describe '#morphology' do
    before :each do
      pending
    end

    context 'with a render' do
      it "defaults to nil" do
        begin
          index.render
        rescue Riddle::Configuration::ConfigurationError
        end

        index.morphology.should be_nil
      end

      it "reads from the settings file if provided" do
        config.settings['morphology'] = 'stem_en'

        begin
          index.render
        rescue Riddle::Configuration::ConfigurationError
        end

        index.morphology.should == 'stem_en'
      end
    end
  end

  describe '#name' do
    it "always uses the core suffix" do
      index = ThinkingSphinx::RealTime::Index.new :user
      index.name.should == 'user_core'
    end
  end

  describe '#offset' do
    before :each do
      config.stub :next_offset => 4
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
      index.should_receive(:interpret_definition!).at_least(:once)

      begin
        index.render
      rescue Riddle::Configuration::ConfigurationError
        # Ignoring underlying validation error.
      end
    end
  end

  describe '#unique_attribute_names' do
    it "returns all attribute names" do
      index.unique_attribute_names.should == [
        'sphinx_internal_id', 'sphinx_internal_class', 'sphinx_deleted'
      ]
    end
  end
end
