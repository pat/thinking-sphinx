require 'spec/spec_helper'
require 'will_paginate/collection'

describe ThinkingSphinx::Search do
  describe "search method" do
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
    
    describe ":star option" do
      
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
  end
  
  describe "facets method" do
    before :each do
      @results = [Person.find(:first)]
      @results.stub!(:each_with_groupby_and_count).
        and_yield(@results.first, @results.first.city.to_crc32, 1)
      ThinkingSphinx::Search.stub!(:search => @results)
      
      @config = ThinkingSphinx::Configuration.instance
      @config.configuration.searchd.max_matches = 10_000
    end
    
    it "should use the system-set max_matches for limit on facet calls" do
      ThinkingSphinx::Search.should_receive(:search) do |options|
        options[:max_matches].should  == 10_000
        options[:limit].should        == 10_000
      end
      
      ThinkingSphinx::Search.facets :all_attributes => true
    end
    
    it "should use the default max-matches if there is no explicit setting" do
      @config.configuration.searchd.max_matches = nil
      ThinkingSphinx::Search.should_receive(:search) do |options|
        options[:max_matches].should  == 1000
        options[:limit].should        == 1000
      end
      
      ThinkingSphinx::Search.facets :all_attributes => true
    end
    
    it "should ignore user-provided max_matches and limit on facet calls" do
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
  end
end

describe ThinkingSphinx::Search, "playing nice with Search model" do
  it "should not conflict with models called Search" do
    lambda { Search.find(:all) }.should_not raise_error
  end
end
