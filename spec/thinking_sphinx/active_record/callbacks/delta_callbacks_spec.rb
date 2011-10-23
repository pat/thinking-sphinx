require 'spec_helper'

describe ThinkingSphinx::ActiveRecord::Callbacks::DeltaCallbacks do
  let(:callbacks)  {
    ThinkingSphinx::ActiveRecord::Callbacks::DeltaCallbacks.new instance
  }
  let(:instance)   { double('instance', :delta? => true) }
  let(:controller) { double('controller') }
  let(:config)     { double('config', :controller => controller) }

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
    it "does not fire a delta index when no indices" do
      config.stub :indices_for_reference => []

      controller.should_not_receive(:index)

      callbacks.after_commit
    end

    it "does not fire a delta index when no delta indices" do
      config.stub :indices_for_reference => [double('index', :delta? => false)]

      controller.should_not_receive(:index)

      callbacks.after_commit
    end

    it "indexes any delta indices" do
      index = double('index', :delta? => true, :name => 'foo_delta')
      config.stub :indices_for_reference => [index]

      controller.should_receive(:index).with('foo_delta')

      callbacks.after_commit
    end

    it "only indexes delta indices" do
      core_index  = double('index', :delta? => false, :name => 'foo_core')
      delta_index = double('index', :delta? => true,  :name => 'foo_delta')
      config.stub :indices_for_reference => [core_index, delta_index]

      controller.should_receive(:index).with('foo_delta')

      callbacks.after_commit
    end

    it "does not index if model's delta flag is not true" do
      index = double('index', :delta? => true, :name => 'foo_delta')
      config.stub :indices_for_reference => [index]
      instance.stub :delta? => false

      controller.should_not_receive(:index)

      callbacks.after_commit
    end
  end

  describe '#before_save' do
    it "sets delta to true if there are delta indices" do
      config.stub :indices_for_reference => [double('index', :delta? => true)]

      instance.should_receive(:delta=).with(true)

      callbacks.before_save
    end

    it "does not try to set delta to true if there are no delta indices" do
      config.stub :indices_for_reference => [double('index', :delta? => false)]

      instance.should_not_receive(:delta=)

      callbacks.before_save
    end
  end
end
