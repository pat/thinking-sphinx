require 'spec_helper'

describe ThinkingSphinx::Index do
  let(:configuration)  { Struct.new(:indices, :settings).new([], {}) }
  
  before :each do
    ThinkingSphinx::Configuration.stub :instance => configuration
  end
  
  describe '.define' do
    let(:index)   { double('index', :definition_block= => nil) }
    
    context 'with ActiveRecord' do
      before :each do
        ThinkingSphinx::ActiveRecord::Index.stub :new => index
      end

      it "creates an ActiveRecord index" do
        ThinkingSphinx::ActiveRecord::Index.should_receive(:new).
          with(:user, :with => :active_record).and_return index

        ThinkingSphinx::Index.define(:user, :with => :active_record)
      end

      it "returns the ActiveRecord index" do
        ThinkingSphinx::Index.define(:user, :with => :active_record).
          should == [index]
      end

      it "adds the index to the collection of indices" do
        ThinkingSphinx::Index.define(:user, :with => :active_record)

        configuration.indices.should include(index)
      end

      it "sets the block in the index" do
        index.should_receive(:definition_block=).with instance_of(Proc)

        ThinkingSphinx::Index.define(:user, :with => :active_record) do
          indexes name
        end
      end

      context 'with a delta' do
        let(:delta_index) { double('delta index', :definition_block= => nil) }
        let(:processor)   { double('delta processor') }

        before :each do
          ThinkingSphinx::Deltas.stub :processor_for => processor
          ThinkingSphinx::ActiveRecord::Index.stub(:new).
            and_return(index, delta_index)
        end

        it "creates two indices with delta settings" do
          ThinkingSphinx::ActiveRecord::Index.unstub :new
          ThinkingSphinx::ActiveRecord::Index.should_receive(:new).
            with(:user,
              hash_including(:delta? => false, :delta_processor => processor)
            ).once.
            and_return index
          ThinkingSphinx::ActiveRecord::Index.should_receive(:new).
            with(:user,
              hash_including(:delta? => true,  :delta_processor => processor)
            ).once.
            and_return delta_index

          ThinkingSphinx::Index.define :user,
            :with  => :active_record,
            :delta => true
        end

        it "appends both indices to the collection" do
          ThinkingSphinx::Index.define :user,
            :with  => :active_record,
            :delta => true

          configuration.indices.should include(index)
          configuration.indices.should include(delta_index)
        end

        it "sets the block in the index" do
          index.should_receive(:definition_block=).with instance_of(Proc)
          delta_index.should_receive(:definition_block=).with instance_of(Proc)

          ThinkingSphinx::Index.define(:user,
            :with  => :active_record,
            :delta => true) do
            indexes name
          end
        end
      end
    end

    context 'with Real-Time' do
      before :each do
        ThinkingSphinx::RealTime::Index.stub :new => index
      end

      it "creates a real-time index" do
        ThinkingSphinx::RealTime::Index.should_receive(:new).
          with(:user, :with => :real_time).and_return index

        ThinkingSphinx::Index.define(:user, :with => :real_time)
      end

      it "returns the ActiveRecord index" do
        ThinkingSphinx::Index.define(:user, :with => :real_time).
          should == [index]
      end

      it "adds the index to the collection of indices" do
        ThinkingSphinx::Index.define(:user, :with => :real_time)

        configuration.indices.should include(index)
      end

      it "sets the block in the index" do
        index.should_receive(:definition_block=).with instance_of(Proc)

        ThinkingSphinx::Index.define(:user, :with => :real_time) do
          indexes name
        end
      end
    end
  end
  
  describe '#initialize' do
    it "is fine with no defaults from settings" do
      ThinkingSphinx::Index.new(:user, {}).options.should == {}
    end
    
    it "respects defaults from settings" do
      configuration.settings['index_options'] = {'delta' => true}
      
      ThinkingSphinx::Index.new(:user, {}).options.should == {:delta => true}
    end
  end
end
