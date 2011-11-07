require 'spec_helper'

describe ThinkingSphinx::Search::Scopes do
  let(:search)      { ThinkingSphinx::Search.new 'foo' }
  let(:translator)  { double('translator', :to_active_record => []) }
  let(:inquirer)    { double('inquirer', :raw => []) }
  let(:stale_retry) { double('retrier') }

  before :each do
    ThinkingSphinx::Search::Translator.stub :new => translator
    ThinkingSphinx::Search::Inquirer.stub :new => inquirer
    ThinkingSphinx::Search::RetryOnStaleIds.stub :new => stale_retry

    inquirer.stub :populate => inquirer
    stale_retry.stub(:try_with_stale).and_yield
  end

  describe '#search' do
    it "replaces the query if one is supplied" do
      search.search('bar')

      search.query.should == 'bar'
    end

    it "keeps the existing query when only options are offered" do
      search.search :with => {:foo => :bar}

      search.query.should == 'foo'
    end

    it "merges conditions" do
      search.options[:conditions] = {:foo => 'bar'}

      search.search :conditions => {:baz => 'qux'}

      search.options[:conditions].should == {:foo => 'bar', :baz => 'qux'}
    end

    it "merges filters" do
      search.options[:with] = {:foo => :bar}

      search.search :with => {:baz => :qux}

      search.options[:with].should == {:foo => :bar, :baz => :qux}
    end

    it "merges exclusive filters" do
      search.options[:without] = {:foo => :bar}

      search.search :without => {:baz => :qux}

      search.options[:without].should == {:foo => :bar, :baz => :qux}
    end

    it "appends excluded ids" do
      search.options[:without_ids] = [1, 3]

      search.search :without_ids => [5, 7]

      search.options[:without_ids].should == [1, 3, 5, 7]
    end

    it "replaces the retry_stale option" do
      search.options[:retry_stale] = true

      search.search :retry_stale => 6

      search.options[:retry_stale].should == 6
    end

    it "returns the original search object" do
      search.search.object_id.should == search.object_id
    end
  end
end
