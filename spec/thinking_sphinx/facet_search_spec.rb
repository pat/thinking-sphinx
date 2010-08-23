require 'spec_helper'

describe ThinkingSphinx::FacetSearch do
  let(:search) { stub('search', :append_to => nil, :empty? => true) }
  let(:config) { ThinkingSphinx::Configuration.instance }
  let(:client) { stub('client', :run => []) }
  
  before :each do
    config.stub!(:client => client)
  end
  
  describe 'populate' do
    before :each do
      config.configuration.searchd.max_matches = 10_000
    end
        
    it "should request all shared facets in a multi-model request by default" do
      ThinkingSphinx.stub!(:search => search)
      ThinkingSphinx::FacetSearch.new.facet_names.should == ['class_crc']
    end
    
    it "should request all facets in a multi-model request if specified" do
      ThinkingSphinx.stub!(:search => search)
      ThinkingSphinx::FacetSearch.new(
        :all_facets => true
      ).facet_names.should == [
        'class_crc', 'city_facet', 'state_facet', 'birthday'
      ]
    end
    
    it "should use the system-set max_matches for limit on facet calls" do
      ThinkingSphinx.should_receive(:search) do |options|
        options[:max_matches].should  == 10_000
        options[:limit].should        == 10_000
        search
      end
      
      ThinkingSphinx::FacetSearch.new
    end
    
    it "should use the default max-matches if there is no explicit setting" do
      config.configuration.searchd.max_matches = nil
      ThinkingSphinx.should_receive(:search) do |options|
        options[:max_matches].should  == 1000
        options[:limit].should        == 1000
        search
      end
      
      ThinkingSphinx::FacetSearch.new
    end
    
    it "should ignore user-provided max_matches and limit on facet calls" do
      ThinkingSphinx.should_receive(:search) do |options|
        options[:max_matches].should  == 10_000
        options[:limit].should        == 10_000
        search
      end
      
      ThinkingSphinx::FacetSearch.new(
        :max_matches    => 500,
        :limit          => 200
      )
    end
    
    it "should not use an explicit :page" do
      ThinkingSphinx.should_receive(:search) do |options|
        options[:page].should == 1
        search
      end
      
      ThinkingSphinx::FacetSearch.new(:page => 3)
    end
    
    describe "conflicting facets" do
      before :each do
        @index = ThinkingSphinx::Index::Builder.generate(Alpha) do
          indexes :name
          has :value, :as => :city, :facet => true
        end
      end
      
      after :each do
        Alpha.sphinx_facets.delete_at(-1)
      end
      
      it "should raise an error if searching with facets of same name but different type" do
        lambda {
          facets = ThinkingSphinx.facets :all_facets => true
        }.should raise_error
      end
    end
    
    describe ':facets option' do
      it "should limit facets to the requested set" do
        ThinkingSphinx.should_receive(:search).once.and_return(search)
        
        ThinkingSphinx::FacetSearch.new(
          :classes => [Person], :facets => :state
        )
      end
    end
    
    describe "empty result set for attributes" do
      before :each do
        ThinkingSphinx.stub!(:search => search)
        @facets = ThinkingSphinx::FacetSearch.new(
          :classes => [Person], :facets => :state
        )
      end
      
      it "should add key as attribute" do
        @facets.should have_key(:state)
      end

      it "should return an empty hash for the facet results" do
        @facets[:state].should be_empty
      end
    end

    describe "non-empty result set" do
      before :each do
        @person = Person.find(:first)
        @people = [@person]
        search.stub!(:empty? => false)
        search.stub!(:each_with_match).
          and_yield(@person, {:attributes => {'@groupby' => @person.city.to_crc32, '@count' => 1}})
        ThinkingSphinx::Search.stub!(:bundle_searches => [search])
        
        @facets = ThinkingSphinx::FacetSearch.new(
          :classes => [Person], :facets => :city
        )
      end

      it "should return a hash" do
        @facets.should be_a_kind_of(Hash)
      end

      it "should add key as attribute" do
        @facets.keys.should include(:city)
      end

      it "should return a hash" do
        @facets[:city].should == {@person.city => 1}
      end
    end
  end
  
  describe "#for" do
    before do
      @person = Person.find(:first)
      @people = [@person]
      search.stub!(:each_with_match).
        and_yield(@person, {:attributes => {'@groupby' => @person.city.to_crc32, '@count' => 1}})
      ThinkingSphinx::Search.stub!(:bundle_searches => [search])
      
      @facets = ThinkingSphinx::FacetSearch.new(
        :classes => [Person], :facets => :city
      )
    end

    it "should return the search results for the attribute and key pair" do
      ThinkingSphinx.should_receive(:search) do |options|
        options[:with].should have_key('city_facet')
        options[:with]['city_facet'].should == @person.city.to_crc32
      end
      
      @facets.for(:city => @person.city)
    end
  end
end
