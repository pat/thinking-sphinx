module ThinkingSphinx; end

require 'thinking_sphinx/facet_search'

describe ThinkingSphinx::FacetSearch do
  let(:facet_search)  { ThinkingSphinx::FacetSearch.new '', {} }
  let(:batch)         { double('batch', :searches => [], :populate => true) }
  let(:index_set)     { [] }
  let(:index)         { double('index', :facets => ['price_bracket'],
      :name => 'foo_core') }

  before :each do
    stub_const 'ThinkingSphinx::IndexSet',      double(:new => index_set)
    stub_const 'ThinkingSphinx::BatchedSearch', double(:new => batch)
    stub_const 'ThinkingSphinx::Search',        DumbSearch

    index_set << index << double('index', :facets => [], :name => 'bar_core')
  end

  DumbSearch = ::Struct.new(:query, :options) do
    def raw
      [{
        'sphinx_internal_class' => 'Foo',
        'price_bracket'         => 3,
        '@count'                => 5
      }]
    end
  end

  describe '#[]' do
    it "populates facet results" do
      facet_search[:price_bracket].should == {3 => 5}
    end
  end

  describe '#populate' do
    it "queries on each facet with a grouped search in a batch" do
      facet_search.populate

      batch.searches.detect { |search|
        search.options[:group_by] == 'price_bracket'
      }.should_not be_nil
    end

    it "limits query for a facet to just indices that have that facet" do
      facet_search.populate

      batch.searches.detect { |search|
        search.options[:indices] == ['foo_core']
      }.should_not be_nil
    end

    it "aliases the class facet from sphinx_internal_class" do
      index.facets.replace ['sphinx_internal_class']

      facet_search.populate

      facet_search[:class].should == {'Foo' => 5}
    end
  end
end
