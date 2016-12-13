require 'spec_helper'

describe ThinkingSphinx::ActiveRecord::Callbacks::DeltaCallbacks do
  let(:callbacks)  {
    ThinkingSphinx::ActiveRecord::Callbacks::DeltaCallbacks.new instance
  }
  let(:instance)   { double('instance', :delta? => true) }
  let(:config)     { double('config') }
  let(:processor)  {
    double('processor', :toggled? => true, :index => true, :delete => true)
  }

  before :each do
    allow(ThinkingSphinx::Configuration).to receive_messages :instance => config
  end

  [:after_commit, :before_save].each do |callback|
    describe ".#{callback}" do
      let(:callbacks) { double('callbacks', callback => nil) }

      before :each do
        allow(ThinkingSphinx::ActiveRecord::Callbacks::DeltaCallbacks).
          to receive_messages :new => callbacks
      end

      it "builds an object from the instance" do
        expect(ThinkingSphinx::ActiveRecord::Callbacks::DeltaCallbacks).
          to receive(:new).with(instance).and_return(callbacks)

        ThinkingSphinx::ActiveRecord::Callbacks::DeltaCallbacks.
          send(callback, instance)
      end

      it "invokes #{callback} on the object" do
        expect(callbacks).to receive(callback)

        ThinkingSphinx::ActiveRecord::Callbacks::DeltaCallbacks.
          send(callback, instance)
      end
    end
  end

  describe '#after_commit' do
    let(:index) {
      double('index', :delta? => false, :delta_processor => processor)
    }

    before :each do
      allow(config).to receive_messages :index_set_class => double(:new => [index])
    end

    context 'without delta indices' do
      it "does not fire a delta index when no delta indices" do
        expect(processor).not_to receive(:index)

        callbacks.after_commit
      end

      it "does not delete the instance from any index" do
        expect(processor).not_to receive(:delete)

        callbacks.after_commit
      end
    end

    context 'with delta indices' do
      let(:core_index) { double('index', :delta? => false, :name => 'foo_core',
        :delta_processor => processor) }
      let(:delta_index) { double('index', :delta? => true, :name => 'foo_delta',
        :delta_processor => processor) }

      before :each do
        allow(ThinkingSphinx::Deltas).to receive_messages :suspended? => false

        allow(config).to receive_messages :index_set_class => double(
          :new => [core_index, delta_index]
        )
      end

      it "only indexes delta indices" do
        expect(processor).to receive(:index).with(delta_index)

        callbacks.after_commit
      end

      it "does not process delta indices when deltas are suspended" do
        allow(ThinkingSphinx::Deltas).to receive_messages :suspended? => true

        expect(processor).not_to receive(:index)

        callbacks.after_commit
      end

      it "deletes the instance from the core index" do
        expect(processor).to receive(:delete).with(core_index, instance)

        callbacks.after_commit
      end

      it "does not index if model's delta flag is not true" do
        allow(processor).to receive_messages :toggled? => false

        expect(processor).not_to receive(:index)

        callbacks.after_commit
      end

      it "does not delete if model's delta flag is not true" do
        allow(processor).to receive_messages :toggled? => false

        expect(processor).not_to receive(:delete)

        callbacks.after_commit
      end

      it "does not delete when deltas are suspended" do
        allow(ThinkingSphinx::Deltas).to receive_messages :suspended? => true

        expect(processor).not_to receive(:delete)

        callbacks.after_commit
      end
    end
  end

  describe '#before_save' do
    let(:index) {
      double('index', :delta? => true, :delta_processor => processor)
    }

    before :each do
      allow(config).to receive_messages :index_set_class => double(:new => [index])
      allow(instance).to receive_messages(
        :changed?    => true,
        :new_record? => false
      )
    end

    it "sets delta to true if there are delta indices" do
      expect(processor).to receive(:toggle).with(instance)

      callbacks.before_save
    end

    it "does not try to set delta to true if there are no delta indices" do
      allow(index).to receive_messages :delta? => false

      expect(processor).not_to receive(:toggle)

      callbacks.before_save
    end

    it "does not try to set delta to true if the instance is unchanged" do
      allow(instance).to receive_messages :changed? => false

      expect(processor).not_to receive(:toggle)

      callbacks.before_save
    end

    it "does set delta to true if the instance is unchanged but new" do
      allow(instance).to receive_messages(
        :changed?    => false,
        :new_record? => true
      )

      expect(processor).to receive(:toggle)

      callbacks.before_save
    end
  end
end
