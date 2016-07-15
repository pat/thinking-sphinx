require 'spec_helper'

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
  let(:configuration) { double 'configuration', :settings => {}, :index_set_class => double(:new => index_set) }

  before :each do
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
        'sphinx_internal_class'                    => 'Foo',
        'price_bracket'                            => 3,
        'tag_ids'                                  => '1,2',
        'category_id'                              => 11,
        ThinkingSphinx::SphinxQL.count[:column]    => 5,
        ThinkingSphinx::SphinxQL.group_by[:column] => 2
      }]
    end
  end

  describe '#[]' do
    it "populates facet results" do
      expect(facet_search[:price_bracket]).to eq({3 => 5})
    end
  end

  describe '#populate' do
    it "queries on each facet with a grouped search in a batch" do
      facet_search.populate

      expect(batch.searches.detect { |search|
        search.options[:group_by] == 'price_bracket'
      }).not_to be_nil
    end

    it "limits query for a facet to just indices that have that facet" do
      facet_search.populate

      expect(batch.searches.detect { |search|
        search.options[:indices] == ['foo_core']
      }).not_to be_nil
    end

    it "limits facets to the specified set" do
      facet_search.options[:facets] = [:category_id]

      facet_search.populate

      expect(batch.searches.collect { |search|
        search.options[:group_by]
      }).to eq(['category_id'])
    end

    it "aliases the class facet from sphinx_internal_class" do
      allow(property_a).to receive_messages :name => 'sphinx_internal_class'

      facet_search.populate

      expect(facet_search[:class]).to eq({'Foo' => 5})
    end

    it "uses the @groupby value for MVAs" do
      allow(property_a).to receive_messages :name => 'tag_ids', :multi? => true

      facet_search.populate

      expect(facet_search[:tag_ids]).to eq({2 => 5})
    end

    [:max_matches, :limit].each do |setting|
      it "sets #{setting} in each search" do
        facet_search.populate

        batch.searches.each { |search|
          expect(search.options[setting]).to eq(1000)
        }
      end

      it "respects configured max_matches values for #{setting}" do
        configuration.settings['max_matches'] = 1234

        facet_search.populate

        batch.searches.each { |search|
          expect(search.options[setting]).to eq(1234)
        }
      end
    end

    [:limit, :per_page].each do |setting|
      it "respects #{setting} option if set" do
        facet_search = ThinkingSphinx::FacetSearch.new '', {setting => 42}

        facet_search.populate

        batch.searches.each { |search|
          expect(search.options[setting]).to eq(42)
        }
      end

      it "allows separate #{setting} and max_matches settings to support pagination" do
        configuration.settings['max_matches'] = 500
        facet_search = ThinkingSphinx::FacetSearch.new '', {setting => 10}

        facet_search.populate

        batch.searches.each do |search|
          expect(search.options[setting]).to eq(10)
          expect(search.options[:max_matches]).to eq(500)
        end
      end
    end
  end
end
