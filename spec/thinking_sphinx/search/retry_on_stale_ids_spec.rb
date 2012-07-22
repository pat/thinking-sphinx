require 'spec_helper'

describe ThinkingSphinx::Search::RetryOnStaleIds do
  let(:retrier) { ThinkingSphinx::Search::RetryOnStaleIds.new search }
  let(:search)  {
    double('search', :stale_retries => 2, :options => {}, :reset! => true)
  }

  describe '#try_with_stale' do
    let(:block) { Proc.new {} }

    it "calls the given block" do
      block.should_receive(:call)

      retrier.try_with_stale do
        block.call
      end
    end

    context 'one stale ids exception' do
      let(:block) {
        Proc.new {
          @calls ||= 0
          @calls += 1
          raise ThinkingSphinx::Search::StaleIdsException, [12] if @calls == 1
        }
      }

      it "appends the ids to the without_ids filter" do
        retrier.try_with_stale &block

        search.options[:without_ids].should == [12]
      end

      it "respects existing without_ids filters" do
        search.options[:without_ids] = [11]

        retrier.try_with_stale &block

        search.options[:without_ids].should == [11, 12]
      end

      it "stores the stale ids" do
        retrier.try_with_stale &block

        retrier.stale_ids.should == [12]
      end

      it "decrements the retry count" do
        retrier.try_with_stale &block

        retrier.retries.should == 1
      end
    end

    context  'two stale ids exceptions' do
      let(:block) {
        Proc.new {
          @calls ||= 0
          @calls += 1
          raise ThinkingSphinx::Search::StaleIdsException, [12] if @calls == 1
          raise ThinkingSphinx::Search::StaleIdsException, [13] if @calls == 2
        }
      }

      it "appends the ids to the without_ids filter" do
        retrier.try_with_stale &block

        search.options[:without_ids].should == [12, 13]
      end

      it "respects existing without_ids filters" do
        search.options[:without_ids] = [11]

        retrier.try_with_stale &block

        search.options[:without_ids].should == [11, 12, 13]
      end

      it "stores the stale ids" do
        retrier.try_with_stale &block

        retrier.stale_ids.should == [12, 13]
      end

      it "decrements the retry count" do
        retrier.try_with_stale &block

        retrier.retries.should == 0
      end
    end

    context 'three stale ids exceptions' do
      let(:block) {
        Proc.new {
          @calls ||= 0
          @calls += 1

          raise ThinkingSphinx::Search::StaleIdsException, [12] if @calls == 1
          raise ThinkingSphinx::Search::StaleIdsException, [13] if @calls == 2
          raise ThinkingSphinx::Search::StaleIdsException, [14] if @calls == 3
        }
      }

      it "raises the final stale ids exceptions" do
        lambda {
          retrier.try_with_stale &block
        }.should raise_error(ThinkingSphinx::Search::StaleIdsException) { |err|
          err.ids.should == [14]
        }
      end
    end
  end
end
