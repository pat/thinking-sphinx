module ThinkingSphinx
  module Masks; end
end

require 'active_support/core_ext/object/blank'
require 'thinking_sphinx/masks/pagination_mask'

describe ThinkingSphinx::Masks::PaginationMask do
  let(:search) { double('search', :options => {}, :meta => {},
    :per_page => 20) }
  let(:mask)   { ThinkingSphinx::Masks::PaginationMask.new search }

  describe '#first_page?' do
    it "returns true when on the first page" do
      mask.should be_first_page
    end

    it "returns false on other pages" do
      search.options[:page] = 2

      mask.should_not be_first_page
    end
  end

  describe '#last_page?' do
    before :each do
      search.meta['total'] = '44'
    end

    it "is true when there's no more pages" do
      search.options[:page] = 3

      mask.should be_last_page
    end

    it "is false when there's still more pages" do
      mask.should_not be_last_page
    end
  end

  describe '#next_page' do
    before :each do
      search.meta['total'] = '44'
    end

    it "should return one more than the current page" do
      mask.next_page.should == 2
    end

    it "should return nil if on the last page" do
      search.options[:page] = 3

      mask.next_page.should be_nil
    end
  end

  describe '#next_page?' do
    before :each do
      search.meta['total'] = '44'
    end

    it "is true when there is a second page" do
      mask.next_page?.should be_true
    end

    it "is false when there's no more pages" do
      search.options[:page] = 3

      mask.next_page?.should be_false
    end
  end

  describe '#previous_page' do
    before :each do
      search.meta['total'] = '44'
    end

    it "should return one less than the current page" do
      search.options[:page] = 2

      mask.previous_page.should == 1
    end

    it "should return nil if on the first page" do
      mask.previous_page.should be_nil
    end
  end

  describe '#total_entries' do
    before :each do
      search.meta['total_found'] = '12'
    end

    it "returns the total found from the search request metadata" do
      mask.total_entries.should == 12
    end
  end

  describe '#total_pages' do
    before :each do
      search.meta['total']       = '40'
      search.meta['total_found'] = '44'
    end

    it "uses the total available from the search request metadata" do
      mask.total_pages.should == 2
    end

    it "should allow for custom per_page values" do
      search.stub :per_page => 40

      mask.total_pages.should == 1
    end

    it "should return 0 if there is no index and therefore no results" do
      search.meta.clear

      mask.total_pages.should == 0
    end
  end
end
