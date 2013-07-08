module ThinkingSphinx; end

require 'thinking_sphinx/facet_search'
require 'thinking_sphinx/facet'

describe ThinkingSphinx::FacetSearch do
  let(:facet_search)  { ThinkingSphinx::FacetSearch.new '', {} }
  let(:batch)         { double('batch', :searches => [], :populate => true) }
  let(:index_set)     { [] }
  let(:index)         { double('index', :facets => [property_a, property_b],
    :name => 'foo_core') }
  let(:property_a)    { double('property', :name => 'price_bracket',
    :multi? => false) }
  let(:property_b)    { double('property', :name => 'category_id',
    :multi? => false) }
  let(:configuration) { double 'configuration', :settings => {} }

  before :each do
    stub_const 'ThinkingSphinx::IndexSet',      double(:new => index_set)
    stub_const 'ThinkingSphinx::BatchedSearch', double(:new => batch)
    stub_const 'ThinkingSphinx::Search',        DumbSearch
    stub_const 'ThinkingSphinx::Middlewares::RAW_ONLY', double
    stub_const 'ThinkingSphinx::Configuration',
      double(:instance => configuration)

    index_set << index << double('index', :facets => [], :name => 'bar_core')
  end

  DumbSearch = ::Struct.new(:query, :options) do
    def raw
      [{
        'sphinx_internal_class' => 'Foo',
        'price_bracket'         => 3,
        'tag_ids'               => '1,2',
        'category_id'           => 11,
        '@count'                => 5,
        '@groupby'              => 2
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

    it "limits facets to the specified set" do
      facet_search.options[:facets] = [:category_id]

      facet_search.populate

      batch.searches.collect { |search|
        search.options[:group_by]
      }.should == ['category_id']
    end

    it "aliases the class facet from sphinx_internal_class" do
      property_a.stub :name => 'sphinx_internal_class'

      facet_search.populate

      facet_search[:class].should == {'Foo' => 5}
    end

    it "uses the @groupby value for MVAs" do
      property_a.stub :name => 'tag_ids', :multi? => true

      facet_search.populate

      facet_search[:tag_ids].should == {2 => 5}
    end

    [:max_matches, :limit].each do |setting|
      it "sets #{setting} in each search" do
        facet_search.populate

        batch.searches.each { |search|
          search.options[setting].should == 1000
        }
      end

      it "respects configured max_matches values for #{setting}" do
        configuration.settings['max_matches'] = 1234

        facet_search.populate

        batch.searches.each { |search|
          search.options[setting].should == 1234
        }
      end
    end

    [:limit, :per_page].each do |setting|
      it "respects #{setting} option if set" do
        facet_search = ThinkingSphinx::FacetSearch.new '', {setting => 42}

        facet_search.populate

        batch.searches.each { |search|
          search.options[setting].should == 42
        }
      end
    end
  end
end
