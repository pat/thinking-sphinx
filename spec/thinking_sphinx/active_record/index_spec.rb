# frozen_string_literal: true

require 'spec_helper'

describe ThinkingSphinx::ActiveRecord::Index do
  let(:index)        { ThinkingSphinx::ActiveRecord::Index.new :user }
  let(:config)       { double('config', :settings => {},
    :indices_location => 'location', :next_offset => 8) }

  before :each do
    allow(ThinkingSphinx::Configuration).to receive_messages :instance => config
  end

  describe '#append_source' do
    let(:model)  { double('model', :primary_key => :id,
      :table_exists? => true) }
    let(:source) { double('source') }

    before :each do
      allow(ActiveSupport::Inflector).to receive_messages(:constantize => model)
      allow(ThinkingSphinx::ActiveRecord::SQLSource).to receive_messages :new => source
      allow(config).to receive_messages :next_offset => 17
    end

    it "adds a source to the index" do
      expect(index.sources).to receive(:<<).with(source)

      index.append_source
    end

    it "creates the source with the index's offset" do
      expect(ThinkingSphinx::ActiveRecord::SQLSource).to receive(:new).
        with(model, hash_including(:offset => 17)).and_return(source)

      index.append_source
    end

    it "returns the new source" do
      expect(index.append_source).to eq(source)
    end

    it "defaults to the model's primary key" do
      allow(model).to receive_messages :primary_key => :sphinx_id

      expect(ThinkingSphinx::ActiveRecord::SQLSource).to receive(:new).
        with(model, hash_including(:primary_key => :sphinx_id)).
        and_return(source)

      index.append_source
    end

    it "uses a custom column when set" do
      allow(model).to receive_messages :primary_key => :sphinx_id

      expect(ThinkingSphinx::ActiveRecord::SQLSource).to receive(:new).
        with(model, hash_including(:primary_key => :custom_sphinx_id)).
        and_return(source)

      index = ThinkingSphinx::ActiveRecord::Index.new:user,
        :primary_key => :custom_sphinx_id
      index.append_source
    end

    it "defaults to id if no primary key is set" do
      allow(model).to receive_messages :primary_key => nil

      expect(ThinkingSphinx::ActiveRecord::SQLSource).to receive(:new).
        with(model, hash_including(:primary_key => :id)).
        and_return(source)

      index.append_source
    end
  end

  describe '#delta?' do
    it "defaults to false" do
      expect(index).not_to be_delta
    end

    it "reflects the delta? option" do
      index = ThinkingSphinx::ActiveRecord::Index.new :user, :delta? => true
      expect(index).to be_delta
    end
  end

  describe '#delta_processor' do
    it "creates an instance of the delta processor option" do
      processor       = double('processor')
      processor_class = double('processor class', :new => processor)
      index = ThinkingSphinx::ActiveRecord::Index.new :user,
        :delta_processor => processor_class

      expect(index.delta_processor).to eq(processor)
    end
  end

  describe '#docinfo' do
    it "defaults to extern" do
      expect(index.docinfo).to eq(:extern)
    end

    it "can be disabled" do
      config.settings["skip_docinfo"] = true

      expect(index.docinfo).to be_nil
    end
  end

  describe '#document_id_for_key' do
    it "calculates the document id based on offset and number of indices" do
      allow(config).to receive_message_chain(:indices, :count).and_return(5)
      allow(config).to receive_messages :next_offset => 7

      expect(index.document_id_for_key(123)).to eq(622)
    end
  end

  describe '#interpret_definition!' do
    let(:block) { double('block') }

    before :each do
      index.definition_block = block
    end

    it "interprets the definition block" do
      expect(ThinkingSphinx::ActiveRecord::Interpreter).to receive(:translate!).
        with(index, block)

      index.interpret_definition!
    end

    it "only interprets the definition block once" do
      expect(ThinkingSphinx::ActiveRecord::Interpreter).to receive(:translate!).
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
    context 'with a render' do
      before :each do
        allow(FileUtils).to receive_messages :mkdir_p => true
      end

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
    it "uses the core suffix by default" do
      index = ThinkingSphinx::ActiveRecord::Index.new :user
      expect(index.name).to eq('user_core')
    end

    it "uses the delta suffix when delta? is true" do
      index = ThinkingSphinx::ActiveRecord::Index.new :user, :delta? => true
      expect(index.name).to eq('user_delta')
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
end
