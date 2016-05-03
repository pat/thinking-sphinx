require 'spec_helper'

describe ThinkingSphinx::ActiveRecord::Callbacks::DeleteCallbacks do
  let(:callbacks)  {
    ThinkingSphinx::ActiveRecord::Callbacks::DeleteCallbacks.new instance
  }
  let(:instance)   { double('instance', :delta? => true) }

  describe '.after_destroy' do
    let(:callbacks) { double('callbacks', :after_destroy => nil) }

    before :each do
      ThinkingSphinx::ActiveRecord::Callbacks::DeleteCallbacks.
        stub :new => callbacks
    end

    it "builds an object from the instance" do
      ThinkingSphinx::ActiveRecord::Callbacks::DeleteCallbacks.
        should_receive(:new).with(instance).and_return(callbacks)

      ThinkingSphinx::ActiveRecord::Callbacks::DeleteCallbacks.
        after_destroy(instance)
    end

    it "invokes after_destroy on the object" do
      callbacks.should_receive(:after_destroy)

      ThinkingSphinx::ActiveRecord::Callbacks::DeleteCallbacks.
        after_destroy(instance)
    end
  end

  describe '#after_destroy' do
    let(:index_set)  { double 'index set', :to_a => [index] }
    let(:index)      { double('index', :name => 'foo_core',
      :document_id_for_key => 14, :type => 'plain', :distributed? => false) }
    let(:instance)   { double('instance', :id => 7, :new_record? => false) }

    before :each do
      ThinkingSphinx::IndexSet.stub :new => index_set
    end

    it "performs the deletion for the index and instance" do
      ThinkingSphinx::Deletion.should_receive(:perform).with(index, 7)

      callbacks.after_destroy
    end

    it "doesn't do anything if the instance is a new record" do
      instance.stub :new_record? => true

      ThinkingSphinx::Deletion.should_not_receive(:perform)

      callbacks.after_destroy
    end

    it 'does nothing if callbacks are suspended' do
      ThinkingSphinx::Callbacks.suspend!

      ThinkingSphinx::Deletion.should_not_receive(:perform)

      callbacks.after_destroy

      ThinkingSphinx::Callbacks.resume!
    end
  end
end
