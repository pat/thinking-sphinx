require 'spec_helper'

describe ThinkingSphinx::Search::Pagination do
  let(:search)       { ThinkingSphinx::Search.new }
  let(:meta_results) { [] }
  let(:translator)   { double('translator', :to_active_record => []) }
  let(:inquirer)     { double('inquirer', :raw => [], :meta => {}) }

  before :each do
    ThinkingSphinx::Search::Translator.stub :new => translator
    ThinkingSphinx::Search::Inquirer.stub :new => inquirer

    inquirer.stub :populate => inquirer
  end

  describe '#first_page?' do
    it "returns true when on the first page" do
      search.should be_first_page
    end

    it "returns false on other pages" do
      ThinkingSphinx::Search.new(:page => 2).should_not be_first_page
    end
  end

  describe '#last_page?' do
    before :each do
      inquirer.meta['total'] = '44'
    end

    it "is true when there's no more pages" do
      ThinkingSphinx::Search.new(:page => 3).should be_last_page
    end

    it "is false when there's still more pages" do
      search.should_not be_last_page
    end
  end

  describe '#next_page' do
    before :each do
      inquirer.meta['total'] = '44'
    end

    it "should return one more than the current page" do
      search.next_page.should == 2
    end

    it "should return nil if on the last page" do
      ThinkingSphinx::Search.new(:page => 3).next_page.should be_nil
    end
  end

  describe '#next_page?' do
    before :each do
      inquirer.meta['total'] = '44'
    end

    it "is true when there is a second page" do
      search.next_page?.should be_true
    end

    it "is false when there's no more pages" do
      ThinkingSphinx::Search.new(:page => 3).next_page?.should be_false
    end
  end

  describe '#previous_page' do
    before :each do
      inquirer.meta['total'] = '44'
    end

    it "should return one less than the current page" do
      ThinkingSphinx::Search.new(:page => 2).previous_page.should == 1
    end

    it "should return nil if on the first page" do
      search.previous_page.should be_nil
    end
  end

  describe '#total_entries' do
    before :each do
      inquirer.meta['total_found'] = '12'
    end

    it "returns the total found from the search request metadata" do
      search.total_entries.should == 12
    end
  end

  describe '#total_pages' do
    before :each do
      inquirer.meta['total']       = '40'
      inquirer.meta['total_found'] = '44'
    end

    it "uses the total available from the search request metadata" do
      search.total_pages.should == 2
    end

    it "should allow for custom per_page values" do
      ThinkingSphinx::Search.new(:per_page => 40).total_pages.should == 1
    end

    it "should return 0 if there is no index and therefore no results" do
      inquirer.meta.clear

      search.total_pages.should == 0
    end
  end
end
