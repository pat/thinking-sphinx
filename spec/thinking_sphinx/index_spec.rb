# frozen_string_literal: true

require 'spec_helper'

describe ThinkingSphinx::Index do
  let(:configuration)  { Struct.new(:indices, :settings).new([], {}) }
  
  before :each do
    allow(ThinkingSphinx::Configuration).to receive_messages :instance => configuration
  end
  
  describe '.define' do
    let(:index)   { double('index', :definition_block= => nil) }
    
    context 'with ActiveRecord' do
      before :each do
        allow(ThinkingSphinx::ActiveRecord::Index).to receive_messages :new => index
      end

      it "creates an ActiveRecord index" do
        expect(ThinkingSphinx::ActiveRecord::Index).to receive(:new).
          with(:user, :with => :active_record).and_return index

        ThinkingSphinx::Index.define(:user, :with => :active_record)
      end

      it "returns the ActiveRecord index" do
        expect(ThinkingSphinx::Index.define(:user, :with => :active_record)).
          to eq([index])
      end

      it "adds the index to the collection of indices" do
        ThinkingSphinx::Index.define(:user, :with => :active_record)

        expect(configuration.indices).to include(index)
      end

      it "sets the block in the index" do
        expect(index).to receive(:definition_block=).with instance_of(Proc)

        ThinkingSphinx::Index.define(:user, :with => :active_record) do
          indexes name
        end
      end

      context 'with a delta' do
        let(:delta_index) { double('delta index', :definition_block= => nil) }
        let(:processor)   { double('delta processor') }

        before :each do
          allow(ThinkingSphinx::Deltas).to receive_messages :processor_for => processor
          allow(ThinkingSphinx::ActiveRecord::Index).to receive(:new).
            and_return(index, delta_index)
        end

        it "creates two indices with delta settings" do
          allow(ThinkingSphinx::ActiveRecord::Index).to receive(:new).and_call_original
          expect(ThinkingSphinx::ActiveRecord::Index).to receive(:new).
            with(:user,
              hash_including(:delta? => false, :delta_processor => processor)
            ).once.
            and_return index
          expect(ThinkingSphinx::ActiveRecord::Index).to receive(:new).
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

          expect(configuration.indices).to include(index)
          expect(configuration.indices).to include(delta_index)
        end

        it "sets the block in the index" do
          expect(index).to receive(:definition_block=).with instance_of(Proc)
          expect(delta_index).to receive(:definition_block=).with instance_of(Proc)

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
        allow(ThinkingSphinx::RealTime::Index).to receive_messages :new => index
      end

      it "creates a real-time index" do
        expect(ThinkingSphinx::RealTime::Index).to receive(:new).
          with(:user, :with => :real_time).and_return index

        ThinkingSphinx::Index.define(:user, :with => :real_time)
      end

      it "returns the ActiveRecord index" do
        expect(ThinkingSphinx::Index.define(:user, :with => :real_time)).
          to eq([index])
      end

      it "adds the index to the collection of indices" do
        ThinkingSphinx::Index.define(:user, :with => :real_time)

        expect(configuration.indices).to include(index)
      end

      it "sets the block in the index" do
        expect(index).to receive(:definition_block=).with instance_of(Proc)

        ThinkingSphinx::Index.define(:user, :with => :real_time) do
          indexes name
        end
      end
    end
  end
  
  describe '#initialize' do
    it "is fine with no defaults from settings" do
      expect(ThinkingSphinx::Index.new(:user, {}).options).to eq({})
    end
    
    it "respects defaults from settings" do
      configuration.settings['index_options'] = {'delta' => true}
      
      expect(ThinkingSphinx::Index.new(:user, {}).options).to eq({:delta => true})
    end
  end
end
