module ThinkingSphinx; end

require 'thinking_sphinx/facet_search'

describe ThinkingSphinx::FacetSearch do
  let(:facet_search)  { ThinkingSphinx::FacetSearch.new '', {} }
  let(:batch)         { double('batch', :searches => [], :populate => true) }
  let(:index_set)     { [] }

  before :each do
    stub_const 'ThinkingSphinx::IndexSet',      double(:new => index_set)
    stub_const 'ThinkingSphinx::BatchedSearch', double(:new => batch)
    stub_const 'ThinkingSphinx::Search',        DumbSearch
  end

  DumbSearch = ::Struct.new(:query, :options) do
    def raw; []; end
  end

  describe '#[]' do
    pending
  end

  describe '#populate' do
    let(:index) { double('index', :facets => ['price_bracket']) }

    before :each do
      index_set << index
    end

    it "queries on each facet with a grouped search in a batch" do
      facet_search.populate

      batch.searches.detect { |search|
        search.options[:group_by] == 'price_bracket'
      }.should_not be_nil
    end
  end
end
