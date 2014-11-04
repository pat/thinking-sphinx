require 'spec_helper'

describe ThinkingSphinx::ActiveRecord::Index do
  let(:index)        { ThinkingSphinx::ActiveRecord::Index.new :user }
  let(:indices_path) { double('indices path', :join => '') }
  let(:config)       { double('config', :settings => {},
    :indices_location => indices_path, :next_offset => 8) }

  before :each do
    ThinkingSphinx::Configuration.stub :instance => config
  end

  describe '#append_source' do
    let(:model)  { double('model', :primary_key => :id) }
    let(:source) { double('source') }

    before :each do
      ActiveSupport::Inflector.stub(:constantize => model)
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

    it "defaults to the model's primary key" do
      model.stub :primary_key => :sphinx_id

      ThinkingSphinx::ActiveRecord::SQLSource.should_receive(:new).
        with(model, hash_including(:primary_key => :sphinx_id)).
        and_return(source)

      index.append_source
    end

    it "uses a custom column when set" do
      model.stub :primary_key => :sphinx_id

      ThinkingSphinx::ActiveRecord::SQLSource.should_receive(:new).
        with(model, hash_including(:primary_key => :custom_sphinx_id)).
        and_return(source)

      index = ThinkingSphinx::ActiveRecord::Index.new:user,
        :primary_key => :custom_sphinx_id
      index.append_source
    end

    it "defaults to id if no primary key is set" do
      model.stub :primary_key => nil

      ThinkingSphinx::ActiveRecord::SQLSource.should_receive(:new).
        with(model, hash_including(:primary_key => :id)).
        and_return(source)

      index.append_source
    end
  end

  describe '#delta?' do
    it "defaults to false" do
      index.should_not be_delta
    end

    it "reflects the delta? option" do
      index = ThinkingSphinx::ActiveRecord::Index.new :user, :delta? => true
      index.should be_delta
    end
  end

  describe '#delta_processor' do
    it "creates an instance of the delta processor option" do
      processor       = double('processor')
      processor_class = double('processor class', :new => processor)
      index = ThinkingSphinx::ActiveRecord::Index.new :user,
        :delta_processor => processor_class

      index.delta_processor.should == processor
    end
  end

  describe '#document_id_for_key' do
    it "calculates the document id based on offset and number of indices" do
      config.stub_chain(:indices, :count).and_return(5)
      config.stub :next_offset => 7

      index.document_id_for_key(123).should == 622
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
    context 'with a render' do
      before :each do
        FileUtils.stub :mkdir_p => true
      end

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
    before :each do
      FileUtils.stub :mkdir_p => true
    end

    it "interprets the provided definition" do
      index.should_receive(:interpret_definition!).at_least(:once)

      begin
        index.render
      rescue Riddle::Configuration::ConfigurationError
        # Ignoring underlying validation error.
      end
    end
  end
end
