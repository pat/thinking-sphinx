require 'spec_helper'

describe ThinkingSphinx::Search do
  let(:search)      { ThinkingSphinx::Search.new }
  let(:translator)  { double('translator', :to_active_record => []) }
  let(:inquirer)    { double('inquirer', :raw => [], :meta => {},
    :index_names => ['alpha']) }
  let(:stale_retry) { double('retrier') }

  before :each do
    ThinkingSphinx::Search::Translator.stub :new => translator
    ThinkingSphinx::Search::Inquirer.stub :new => inquirer
    ThinkingSphinx::Search::RetryOnStaleIds.stub :new => stale_retry

    inquirer.stub :populate => inquirer
    stale_retry.stub(:try_with_stale).and_yield
  end

  describe '#current_page' do
    it "should return 1 by default" do
      search.current_page.should == 1
    end

    it "should handle string page values" do
      ThinkingSphinx::Search.new(:page => '2').current_page.should == 2
    end

    it "should handle empty string page values" do
      ThinkingSphinx::Search.new(:page => '').current_page.should == 1
    end

    it "should return the requested page" do
      ThinkingSphinx::Search.new(:page => 10).current_page.should == 10
    end
  end

  describe '#empty?' do
    it "returns false if there is anything in the data set" do
      translator.stub(:to_active_record => [double('instance')])

      search.should_not be_empty
    end

    it "returns true if the data set is empty" do
      translator.stub(:to_active_record => [])

      search.should be_empty
    end
  end

  describe '#excerpter' do
    let(:excerpter) { double('excerpter') }

    it "creates an excerpter with the first index and all keywords" do
      inquirer.stub :index_names => ['alpha', 'beta', 'gamma']
      inquirer.meta['keyword[0]'] = 'foo'
      inquirer.meta['keyword[1]'] = 'bar'

      ThinkingSphinx::Excerpter.should_receive(:new).
        with('alpha', 'foo bar', anything).and_return(excerpter)

      search.excerpter
    end

    it "returns the generated excerpter" do
      ThinkingSphinx::Excerpter.stub :new => excerpter

      search.excerpter.should == excerpter
    end

    it "passes through excerpts options" do
      search = ThinkingSphinx::Search.new :excerpts => {:before_match => 'foo'}

      ThinkingSphinx::Excerpter.should_receive(:new).
        with(anything, anything, :before_match => 'foo').and_return(excerpter)

      search.excerpter
    end
  end

  describe '#initialize' do
    it "lazily loads by default" do
      inquirer.should_not_receive(:populate)

      ThinkingSphinx::Search.new
    end

    it "should automatically populate when :populate is set to true" do
      inquirer.should_receive(:populate).and_return(inquirer)

      ThinkingSphinx::Search.new(:populate => true)
    end
  end

  describe '#offset' do
    it "should default to 0" do
      search.offset.should == 0
    end

    it "should increase by the per_page value for each page in" do
      ThinkingSphinx::Search.new(:per_page => 25, :page => 2).offset.
        should == 25
    end

    it "should prioritise explicit :offset over calculated if given" do
      ThinkingSphinx::Search.new(:offset => 5).offset.should == 5
    end
  end

  describe '#page' do
    it "sets the current page" do
      search.page(3)
      search.current_page.should == 3
    end

    it "returns the search object" do
      search.page(2).should == search
    end
  end

  describe '#per' do
    it "sets the current per_page value" do
      search.per(29)
      search.per_page.should == 29
    end

    it "returns the search object" do
      search.per(29).should == search
    end
  end

  describe '#per_page' do
    it "defaults to 20" do
      search.per_page.should == 20
    end

    it "is set as part of the search options" do
      ThinkingSphinx::Search.new(:per_page => 10).per_page.should == 10
    end

    it "should prioritise :limit over :per_page if given" do
      ThinkingSphinx::Search.new(:per_page => 30, :limit => 40).per_page.
        should == 40
    end

    it "should allow for string arguments" do
      ThinkingSphinx::Search.new(:per_page => '10').per_page.should == 10
    end
  end

  describe '#populate' do
    it "retrieves the ActiveRecord-translated results" do
      translator.should_receive(:to_active_record).and_return([])

      search.populate
    end

    it "does not retrieve results twice" do
      translator.should_receive(:to_active_record).once.and_return([])

      search.populate
      search.populate
    end
  end

  describe '#respond_to?' do
    it "should respond to Array methods" do
      search.respond_to?(:each).should be_true
    end

    it "should respond to Search methods" do
      search.respond_to?(:per_page).should be_true
    end
  end

  describe '#stale_retries' do
    it "returns 3 by default" do
      search.stale_retries.should == 3
    end

    it "returns 3 when given true" do
      search.options[:retry_stale] = true

      search.stale_retries.should == 3
    end

    it "returns 0 when given false" do
      search.options[:retry_stale] = false

      search.stale_retries.should == 0
    end

    it "respects integer values" do
      search.options[:retry_stale] = 7

      search.stale_retries.should == 7
    end
  end

  describe '#to_a' do
    it "returns each of the standard ActiveRecord objects" do
      unglazed = double('unglazed instance')
      glazed   = double('glazed instance', :unglazed => unglazed)

      translator.stub(:to_active_record => [glazed])

      search.to_a.first.__id__.should == unglazed.__id__
    end
  end
end
