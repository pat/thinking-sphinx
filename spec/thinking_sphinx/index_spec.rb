require 'spec_helper'

describe ThinkingSphinx::Index do
  describe '.define' do
    context 'with ActiveRecord' do
      let(:index)   { double('index', :definition_block= => nil) }
      let(:config)  { double('config', :indices => indices) }
      let(:indices) { double('indices', :<< => true) }

      before :each do
        ThinkingSphinx::ActiveRecord::Index.stub! :new => index
        ThinkingSphinx::Configuration.stub! :instance => config
      end

      it "creates an ActiveRecord index" do
        ThinkingSphinx::ActiveRecord::Index.should_receive(:new).
          with(:user).and_return index

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
    end
  end
end
