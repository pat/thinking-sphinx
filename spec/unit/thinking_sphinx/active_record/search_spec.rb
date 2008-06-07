require 'spec/spec_helper'

describe "ThinkingSphinx::ActiveRecord::Search" do
  it "should add search_for_ids to ActiveRecord::Base" do
    ActiveRecord::Base.methods.should include("search_for_ids")
  end
  
  it "should add search_for_ids to ActiveRecord::Base" do
    ActiveRecord::Base.methods.should include("search")
  end
  
  describe "search_for_ids method" do
    before :each do
      ThinkingSphinx::Search.stub_method(:search_for_ids => true)
    end
    
    after :each do
      ThinkingSphinx::Search.unstub_method(:search_for_ids)
    end
    
    it "should call ThinkingSphinx::Search#search_for_ids with the class option set" do
      Person.search_for_ids("search")
      
      ThinkingSphinx::Search.should have_received(:search_for_ids).with(
        "search", :class => Person
      )
    end
    
    it "should override the class option" do
      Person.search_for_ids("search", :class => Friendship)
      
      ThinkingSphinx::Search.should have_received(:search_for_ids).with(
        "search", :class => Person
      )
    end
  end
  
  describe "search method" do
    before :each do
      ThinkingSphinx::Search.stub_method(:search => true)
    end
    
    after :each do
      ThinkingSphinx::Search.unstub_method(:search)
    end
    
    it "should call ThinkingSphinx::Search#search with the class option set" do
      Person.search("search")
      
      ThinkingSphinx::Search.should have_received(:search).with(
        "search", :class => Person
      )
    end
    
    it "should override the class option" do
      Person.search("search", :class => Friendship)
      
      ThinkingSphinx::Search.should have_received(:search).with(
        "search", :class => Person
      )
    end
  end
end