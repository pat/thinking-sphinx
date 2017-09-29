require 'spec_helper'

describe ThinkingSphinx::ActiveRecord::Callbacks::DeleteCallbacks do
  let(:callbacks)  {
    ThinkingSphinx::ActiveRecord::Callbacks::DeleteCallbacks.new instance
  }
  let(:instance)   { double('instance', :delta? => true) }

  describe '.after_destroy' do
    let(:callbacks) { double('callbacks', :after_destroy => nil) }

    before :each do
      allow(ThinkingSphinx::ActiveRecord::Callbacks::DeleteCallbacks).
        to receive_messages :new => callbacks
    end

    it "builds an object from the instance" do
      expect(ThinkingSphinx::ActiveRecord::Callbacks::DeleteCallbacks).
        to receive(:new).with(instance).and_return(callbacks)

      ThinkingSphinx::ActiveRecord::Callbacks::DeleteCallbacks.
        after_destroy(instance)
    end

    it "invokes after_destroy on the object" do
      expect(callbacks).to receive(:after_destroy)

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
      allow(ThinkingSphinx::IndexSet).to receive_messages :new => index_set
    end

    it "performs the deletion for the index and instance" do
      expect(ThinkingSphinx::Deletion).to receive(:perform).with(index, 7)

      callbacks.after_destroy
    end

    it "doesn't do anything if the instance is a new record" do
      allow(instance).to receive_messages :new_record? => true

      expect(ThinkingSphinx::Deletion).not_to receive(:perform)

      callbacks.after_destroy
    end

    it 'does nothing if callbacks are suspended' do
      ThinkingSphinx::Callbacks.suspend!

      expect(ThinkingSphinx::Deletion).not_to receive(:perform)

      callbacks.after_destroy

      ThinkingSphinx::Callbacks.resume!
    end
  end

  describe '.after_rollback' do
    let(:callbacks) { double('callbacks', :after_rollback => nil) }

    before :each do
      allow(ThinkingSphinx::ActiveRecord::Callbacks::DeleteCallbacks).
        to receive_messages :new => callbacks
    end

    it "builds an object from the instance" do
      expect(ThinkingSphinx::ActiveRecord::Callbacks::DeleteCallbacks).
        to receive(:new).with(instance).and_return(callbacks)

      ThinkingSphinx::ActiveRecord::Callbacks::DeleteCallbacks.
        after_rollback(instance)
    end

    it "invokes after_rollback on the object" do
      expect(callbacks).to receive(:after_rollback)

      ThinkingSphinx::ActiveRecord::Callbacks::DeleteCallbacks.
        after_rollback(instance)
    end
  end

  describe '#after_rollback' do
    let(:index_set)  { double 'index set', :to_a => [index] }
    let(:index)      { double('index', :name => 'foo_core',
      :document_id_for_key => 14, :type => 'plain', :distributed? => false) }
    let(:instance)   { double('instance', :id => 7, :new_record? => false) }

    before :each do
      allow(ThinkingSphinx::IndexSet).to receive_messages :new => index_set
    end

    it "performs the deletion for the index and instance" do
      expect(ThinkingSphinx::Deletion).to receive(:perform).with(index, 7)

      callbacks.after_rollback
    end

    it "doesn't do anything if the instance is a new record" do
      allow(instance).to receive_messages :new_record? => true

      expect(ThinkingSphinx::Deletion).not_to receive(:perform)

      callbacks.after_rollback
    end

    it 'does nothing if callbacks are suspended' do
      ThinkingSphinx::Callbacks.suspend!

      expect(ThinkingSphinx::Deletion).not_to receive(:perform)

      callbacks.after_rollback

      ThinkingSphinx::Callbacks.resume!
    end
  end
end
