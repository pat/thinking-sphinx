require 'spec/spec_helper'

describe ThinkingSphinx::SearchMethods do
  it "should be included into models with indexes" do
    Alpha.included_modules.should include(ThinkingSphinx::SearchMethods)
  end
  
  it "should not be included into models that don't have indexes" do
    Gamma.included_modules.should_not include(ThinkingSphinx::SearchMethods)
  end
  
  describe '.search_context' do
    it "should return nil if not within a model" do
      ThinkingSphinx.search_context.should be_nil
    end
    
    it "should return the model if within one" do
      Alpha.search_context.should == Alpha
    end
  end
  
  describe '.search' do
    it "should return an instance of ThinkingSphinx::Search" do
      Alpha.search.class.should == ThinkingSphinx::Search
    end
    
    it "should set the classes option if not already set" do
      search = Alpha.search
      search.options[:classes].should == [Alpha]
    end
    
    it "shouldn't set the classes option if already defined" do
      search = Alpha.search :classes => [Beta]
      search.options[:classes].should == [Beta]
    end
    
    it "should default to nil for the classes options" do
      ThinkingSphinx.search.options[:classes].should be_nil
    end
  end
  
  describe '.search_for_ids' do
    it "should return an instance of ThinkingSphinx::Search" do
      Alpha.search.class.should == ThinkingSphinx::Search
    end
    
    it "should set the classes option if not already set" do
      search = Alpha.search_for_ids
      search.options[:classes].should == [Alpha]
    end
    
    it "shouldn't set the classes option if already defined" do
      search = Alpha.search_for_ids :classes => [Beta]
      search.options[:classes].should == [Beta]
    end
    
    it "should set ids_only to true" do
      search = Alpha.search_for_ids
      search.options[:ids_only].should be_true
    end
  end
  
  describe '.search_for_id' do
    before :each do
      @config = ThinkingSphinx::Configuration.instance
      @client = Riddle::Client.new

      @config.stub!(:client => @client)
      @client.stub!(:query => {:matches => [], :total_found => 0})
    end
    
    it "should set the id range to the given id value" do
      ThinkingSphinx.search_for_id(101, 'alpha_core')
      
      @client.id_range.should == (101..101)
    end
    
    it "should not make any calls to the database" do
      Alpha.should_not_receive(:find)
      
      ThinkingSphinx.search_for_id(101, 'alpha_core', :classes => [Alpha])
    end
    
    it "should return true if there is a record" do
      @client.stub!(:query => {:matches => [
        {:attributes => {'sphinx_internal_id' => 100}}
      ], :total_found => 1})
      
      ThinkingSphinx.search_for_id(101, 'alpha_core').should be_true
    end
    
    it "should return false if there isn't a record" do
      ThinkingSphinx.search_for_id(101, 'alpha_core').should be_false
    end
  end
  
  describe '.count' do
    before :each do
      @config = ThinkingSphinx::Configuration.instance
      @client = Riddle::Client.new

      @config.stub!(:client => @client)
      @client.stub!(:query => {:matches => [], :total_found => 42})
    end
    
    it "should fall through to ActiveRecord if called on a class" do
      @client.should_not_receive(:query)
      
      Alpha.count
    end
    
    it "should return the total number of results if called globally" do
      ThinkingSphinx.count.should == 42
    end
  end
  
  describe '.search_count' do
    before :each do
      @config = ThinkingSphinx::Configuration.instance
      @client = Riddle::Client.new

      @config.stub!(:client => @client)
      @client.stub!(:query => {:matches => [], :total_found => 42})
    end
    
    it "should return the total number of results" do
      Alpha.search_count.should == 42
    end
    
    it "should not make any calls to the database" do
      Alpha.should_not_receive(:find)
      
      Alpha.search_count
    end
  end
  
  describe '.facets' do
    it "should return a FacetSearch instance" do
      Alpha.facets.should be_a(ThinkingSphinx::FacetSearch)
    end
    
    it "should set the classes option if not already set" do
      facets = Alpha.facets
      facets.options[:classes].should == [Alpha]
    end
    
    it "shouldn't set the classes option if already defined" do
      facets = Alpha.facets :classes => [Beta]
      facets.options[:classes].should == [Beta]
    end
  end
end
