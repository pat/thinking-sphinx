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
    ThinkingSphinx::Configuration.stub :instance => config
  end

  [:after_commit, :before_save].each do |callback|
    describe ".#{callback}" do
      let(:callbacks) { double('callbacks', callback => nil) }

      before :each do
        ThinkingSphinx::ActiveRecord::Callbacks::DeltaCallbacks.
          stub :new => callbacks
      end

      it "builds an object from the instance" do
        ThinkingSphinx::ActiveRecord::Callbacks::DeltaCallbacks.
          should_receive(:new).with(instance).and_return(callbacks)

        ThinkingSphinx::ActiveRecord::Callbacks::DeltaCallbacks.
          send(callback, instance)
      end

      it "invokes #{callback} on the object" do
        callbacks.should_receive(callback)

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
      config.stub :indices_for_reference => [index]
    end

    context 'without delta indices' do
      it "does not fire a delta index when no delta indices" do
        processor.should_not_receive(:index)

        callbacks.after_commit
      end

      it "does not delete the instance from any index" do
        processor.should_not_receive(:delete)

        callbacks.after_commit
      end
    end

    context 'with delta indices' do
      let(:core_index) { double('index', :delta? => false, :name => 'foo_core',
        :delta_processor => processor) }
      let(:delta_index) { double('index', :delta? => true, :name => 'foo_delta',
        :delta_processor => processor) }

      before :each do
        config.stub :indices_for_reference => [core_index, delta_index]
      end

      it "only indexes delta indices" do
        processor.should_receive(:index).with(delta_index)

        callbacks.after_commit
      end

      it "deletes the instance from the core index" do
        processor.should_receive(:delete).with(core_index, instance)

        callbacks.after_commit
      end

      it "does not index if model's delta flag is not true" do
        processor.stub :toggled? => false

        processor.should_not_receive(:index)

        callbacks.after_commit
      end

      it "does not delete if model's delta flag is not true" do
        processor.stub :toggled? => false

        processor.should_not_receive(:delete)

        callbacks.after_commit
      end
    end
  end

  describe '#before_save' do
    let(:index) {
      double('index', :delta? => true, :delta_processor => processor)
    }

    before :each do
      config.stub :indices_for_reference => [index]
    end

    it "sets delta to true if there are delta indices" do
      processor.should_receive(:toggle).with(instance)

      callbacks.before_save
    end

    it "does not try to set delta to true if there are no delta indices" do
      index.stub :delta? => false

      processor.should_not_receive(:toggle)

      callbacks.before_save
    end
  end
end
