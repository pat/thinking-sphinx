require 'spec_helper'

describe ThinkingSphinx::Index do
  describe '.define' do
    context 'with ActiveRecord' do
      let(:index)   { double('index', :definition_block= => nil) }
      let(:config)  { double('config', :indices => indices) }
      let(:indices) { double('indices', :<< => true) }

      before :each do
        ThinkingSphinx::ActiveRecord::Index.stub :new => index
        ThinkingSphinx::Configuration.stub :instance => config
      end

      it "creates an ActiveRecord index" do
        ThinkingSphinx::ActiveRecord::Index.should_receive(:new).
          with(:user, :with => :active_record).and_return index

        ThinkingSphinx::Index.define(:user, :with => :active_record)
      end

      it "returns the ActiveRecord index" do
        ThinkingSphinx::Index.define(:user, :with => :active_record).
          should == index
      end

      it "adds the index to the collection of indices" do
        indices.should_receive(:<<).with(index)

        ThinkingSphinx::Index.define(:user, :with => :active_record)
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
          indices.should_receive(:<<).with(index)
          indices.should_receive(:<<).with(delta_index)

          ThinkingSphinx::Index.define :user,
            :with  => :active_record,
            :delta => true
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
  end
end
