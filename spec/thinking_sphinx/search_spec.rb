require 'spec_helper'

describe ThinkingSphinx::Search do
  let(:search)        { ThinkingSphinx::Search.new }
  let(:context)       { {:results => []} }
  let(:stack)         { double('stack', :call => true) }

  let(:pagination_mask_methods) do
    [:first_page?,
     :last_page?,
     :next_page,
     :next_page?,
     :page,
     :per,
     :previous_page,
     :total_entries,
     :total_count,
     :count,
     :total_pages,
     :page_count,
     :num_pages]
  end

  let(:scopes_mask_methods) do
    [:facets,
     :search,
     :search_for_ids]
  end

  let(:group_enumerator_mask_methods) do
    [:each_with_count,
     :each_with_group,
     :each_with_group_and_count]
  end

  before :each do
    allow(ThinkingSphinx::Search::Context).to receive_messages :new => context

    stub_const 'ThinkingSphinx::Middlewares::DEFAULT', stack
  end

  describe '#current_page' do
    it "should return 1 by default" do
      expect(search.current_page).to eq(1)
    end

    it "should handle string page values" do
      expect(ThinkingSphinx::Search.new(:page => '2').current_page).to eq(2)
    end

    it "should handle empty string page values" do
      expect(ThinkingSphinx::Search.new(:page => '').current_page).to eq(1)
    end

    it "should return the requested page" do
      expect(ThinkingSphinx::Search.new(:page => 10).current_page).to eq(10)
    end
  end

  describe '#empty?' do
    it "returns false if there is anything in the data set" do
      context[:results] << double

      expect(search).not_to be_empty
    end

    it "returns true if the data set is empty" do
      context[:results].clear

      expect(search).to be_empty
    end
  end

  describe '#initialize' do
    it "lazily loads by default" do
      expect(stack).not_to receive(:call)

      ThinkingSphinx::Search.new
    end

    it "should automatically populate when :populate is set to true" do
      expect(stack).to receive(:call).and_return(true)

      ThinkingSphinx::Search.new(:populate => true)
    end
  end

  describe '#offset' do
    it "should default to 0" do
      expect(search.offset).to eq(0)
    end

    it "should increase by the per_page value for each page in" do
      expect(ThinkingSphinx::Search.new(:per_page => 25, :page => 2).offset).
        to eq(25)
    end

    it "should prioritise explicit :offset over calculated if given" do
      expect(ThinkingSphinx::Search.new(:offset => 5).offset).to eq(5)
    end
  end

  describe '#page' do
    it "sets the current page" do
      search.page(3)
      expect(search.current_page).to eq(3)
    end

    it "returns the search object" do
      expect(search.page(2)).to eq(search)
    end
  end

  describe '#per' do
    it "sets the current per_page value" do
      search.per(29)
      expect(search.per_page).to eq(29)
    end

    it "returns the search object" do
      expect(search.per(29)).to eq(search)
    end
  end

  describe '#per_page' do
    it "defaults to 20" do
      expect(search.per_page).to eq(20)
    end

    it "is set as part of the search options" do
      expect(ThinkingSphinx::Search.new(:per_page => 10).per_page).to eq(10)
    end

    it "should prioritise :limit over :per_page if given" do
      expect(ThinkingSphinx::Search.new(:per_page => 30, :limit => 40).per_page).
        to eq(40)
    end

    it "should allow for string arguments" do
      expect(ThinkingSphinx::Search.new(:per_page => '10').per_page).to eq(10)
    end

    it "allows setting of the per_page value" do
      search.per_page(24)
      expect(search.per_page).to eq(24)
    end
  end

  describe '#populate' do
    it "runs the middleware" do
      expect(stack).to receive(:call).with([context]).and_return(true)

      search.populate
    end

    it "does not retrieve results twice" do
      expect(stack).to receive(:call).with([context]).once.and_return(true)

      search.populate
      search.populate
    end
  end

  describe '#respond_to?' do
    it "should respond to Array methods" do
      expect(search.respond_to?(:each)).to be_truthy
    end

    it "should respond to Search methods" do
      expect(search.respond_to?(:per_page)).to be_truthy
    end

    it "should return true for methods delegated to pagination mask by method_missing" do
      pagination_mask_methods.each do |method|
        expect(search).to respond_to method
      end
    end

    it "should return true for methods delegated to scopes mask by method_missing" do
      scopes_mask_methods.each do |method|
        expect(search).to respond_to method
      end
    end

    it "should return true for methods delegated to group enumerators mask by method_missing" do
      group_enumerator_mask_methods.each do |method|
        expect(search).to respond_to method
      end
    end
  end

  describe '#to_a' do
    it "returns each of the standard ActiveRecord objects" do
      unglazed = double('unglazed instance')
      glazed   = double('glazed instance', :unglazed => unglazed)

      context[:results] << glazed

      expect(search.to_a.first.__id__).to eq(unglazed.__id__)
    end
  end

  it "correctly handles access to methods delegated to masks through 'method' call" do
    [
      pagination_mask_methods,
      scopes_mask_methods,
      group_enumerator_mask_methods
    ].flatten.each do |method|
      expect { search.method method }.to_not raise_exception
    end
  end
end
