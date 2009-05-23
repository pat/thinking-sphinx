require 'spec/spec_helper'
require 'will_paginate/collection'

describe ThinkingSphinx::Search do
  describe "search method" do
    describe ":star option" do
      before :each do
        @client = Riddle::Client.stub_instance(
          :filters    => [],
          :filters=   => true,
          :id_range=  => true,
          :sort_mode  => :asc,
          :limit      => 5,
          :offset=    => 0,
          :sort_mode= => true,
          :query      => {
            :matches  => [],
            :total    => 50
          }
        )

        ThinkingSphinx::Search.stub_methods(
          :client_from_options => @client,
          :search_conditions   => ["", []]
        )
      end
      
      it "should not apply by default" do
        ThinkingSphinx::Search.search "foo bar"
        @client.should have_received(:query).with("foo bar")
      end

      it "should apply when passed, and handle full extended syntax" do
        input    = %{a b* c (d | e) 123 5&6 (f_f g) !h "i j" "k l"~10 "m n"/3 @o p -(q|r)}
        expected = %{*a* b* *c* (*d* | *e*) *123* *5*&*6* (*f_f* *g*) !*h* "i j" "k l"~10 "m n"/3 @o *p* -(*q*|*r*)}
        ThinkingSphinx::Search.search input, :star => true
        @client.should have_received(:query).with(expected)
      end

      it "should default to /\w+/ as token" do
        ThinkingSphinx::Search.search "foo@bar.com", :star => true
        @client.should have_received(:query).with("*foo*@*bar*.*com*")
      end

      it "should honour custom token" do
        ThinkingSphinx::Search.search "foo@bar.com -foo-bar", :star => /[\w@.-]+/u
        @client.should have_received(:query).with("*foo@bar.com* -*foo-bar*")
      end
    end
    
    describe "sort modes" do
      before :each do
        @client = Riddle::Client.new
        @client.stub_method(:query => {:matches => []})
        Riddle::Client.stub_method(:new => @client)
      end
      
      it "should use :relevance as a default" do
        ThinkingSphinx::Search.search "foo"
        @client.sort_mode.should == :relevance
      end
      
      it "should use :attr_asc if a symbol is supplied to :order" do
        ThinkingSphinx::Search.search "foo", :order => :created_at
        @client.sort_mode.should == :attr_asc
      end
      
      it "should use :attr_desc if a symbol is supplied and :desc is the mode" do
        ThinkingSphinx::Search.search "foo", :order => :created_at, :sort_mode => :desc
        @client.sort_mode.should == :attr_desc
      end
      
      it "should use :extended if a string is supplied to :order" do
        ThinkingSphinx::Search.search "foo", :order => "created_at ASC"
        @client.sort_mode.should == :extended
      end
      
      it "should use :expr if explicitly requested with a string supplied to :order" do
        ThinkingSphinx::Search.search "foo", :order => "created_at ASC", :sort_mode => :expr
        @client.sort_mode.should == :expr
      end
      
      it "should use :attr_desc if explicitly requested with a string supplied to :order" do
        ThinkingSphinx::Search.search "foo", :order => "created_at", :sort_mode => :desc
        @client.sort_mode.should == :attr_desc
      end
    end
  end
  
  describe "facets method" do
    before :each do
      @person = Person.find(:first)
      
      @city_results = [@person]
      @city_results.stub!(:each_with_groupby_and_count).
        and_yield(@person, @person.city.to_crc32, 1)
      
      @birthday_results = [@person]
      @birthday_results.stub!(:each_with_groupby_and_count).
        and_yield(@person, @person.birthday.to_i, 1)
      
      @config = ThinkingSphinx::Configuration.instance
      @config.configuration.searchd.max_matches = 10_000
    end
    
    it "should use the system-set max_matches for limit on facet calls" do
      ThinkingSphinx::Search.stub!(:search).and_return(@city_results, @birthday_results)
      
      ThinkingSphinx::Search.should_receive(:search) do |options|
        options[:max_matches].should  == 10_000
        options[:limit].should        == 10_000
      end
      
      ThinkingSphinx::Search.facets :all_attributes => true
    end
    
    it "should use the default max-matches if there is no explicit setting" do
      ThinkingSphinx::Search.stub!(:search).and_return(@city_results, @birthday_results)
      
      @config.configuration.searchd.max_matches = nil
      ThinkingSphinx::Search.should_receive(:search) do |options|
        options[:max_matches].should  == 1000
        options[:limit].should        == 1000
      end
      
      ThinkingSphinx::Search.facets :all_attributes => true
    end
    
    it "should ignore user-provided max_matches and limit on facet calls" do
      ThinkingSphinx::Search.stub!(:search).and_return(@city_results, @birthday_results)
      
      ThinkingSphinx::Search.should_receive(:search) do |options|
        options[:max_matches].should  == 10_000
        options[:limit].should        == 10_000
      end
      
      ThinkingSphinx::Search.facets(
        :all_attributes => true,
        :max_matches    => 500,
        :limit          => 200
      )
    end
    
    it "should use explicit facet list if one is provided" do
      ThinkingSphinx::Search.should_receive(:search).once.and_return(@city_results)
      
      ThinkingSphinx::Search.facets(
        :facets => ['city'],
        :class  => Person
      )
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
        Alpha.sphinx_indexes.delete_at(-1)
      end
      
      it "should raise an error if searching with facets of same name but different type" do
        lambda {
          ThinkingSphinx::Search.facets :all_attributes => true
        }.should raise_error
      end
    end
  end
end

describe ThinkingSphinx::Search, "playing nice with Search model" do
  it "should not conflict with models called Search" do
    lambda { Search.find(:all) }.should_not raise_error
  end
end
