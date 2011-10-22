require 'spec_helper'

describe ThinkingSphinx::ActiveRecord::Index do
  let(:index)        { ThinkingSphinx::ActiveRecord::Index.new :user }
  let(:indices_path) { double('indices path', :join => '') }
  let(:config)       {
    double('config', :settings => {}, :indices_location => indices_path)
  }

  before :each do
    ThinkingSphinx::Configuration.stub :instance => config
  end

  describe '#append_source' do
    let(:model)  { double('model') }
    let(:source) { double('source') }

    before :each do
      ActiveSupport::Inflector.stub!(:constantize => model)
      ThinkingSphinx::ActiveRecord::SQLSource.stub :new => source
      config.stub :next_offset => 17
    end

    it "adds a source to the index" do
      index.sources.should_receive(:<<).with(source)

      index.append_source
    end

    it "creates the source with the index's offset" do
      ThinkingSphinx::ActiveRecord::SQLSource.should_receive(:new).
        with(model, hash_including(:offset => 17)).and_return(source)

      index.append_source
    end

    it "returns the new source" do
      index.append_source.should == source
    end
  end

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

  describe '#morphology' do
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
    it "uses the core suffix by default" do
      index = ThinkingSphinx::ActiveRecord::Index.new :user
      index.name.should == 'user_core'
    end

    it "uses the delta suffix when delta? is true" do
      index = ThinkingSphinx::ActiveRecord::Index.new :user, :delta? => true
      index.name.should == 'user_delta'
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
      index.should_receive(:interpret_definition!)

      begin
        index.render
      rescue Riddle::Configuration::ConfigurationError
        # Ignoring underlying validation error.
      end
    end
  end
end
