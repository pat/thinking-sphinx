require 'spec/spec_helper'
require 'will_paginate/collection'

describe ThinkingSphinx::Search do
  before :all do
    @sphinx.setup_sphinx
    @sphinx.start
  end
  
  after :all do
    @sphinx.stop
  end
  
  describe "search_for_id method" do
    before :each do
      @client = Riddle::Client.stub_instance(
        :filters    => [],
        :filters=   => true,
        :id_range=  => true,
        :query      => {
          :matches  => []
        }
      )
      
      ThinkingSphinx::Search.stub_methods(
        :client_from_options => @client,
        :search_conditions   => ["", []]
      )
    end
    
    it "should set the client id range to focus on the given id" do
      ThinkingSphinx::Search.search_for_id 42, "an_index"
      
      @client.should have_received(:id_range=).with(42..42)
    end
    
    it "should query on the given index" do
      ThinkingSphinx::Search.search_for_id 42, "an_index"
      
      @client.should have_received(:query).with("", "an_index")
    end
    
    it "should return true if a record is returned" do
      @client.stub_method(:query => {
        :matches => [24]
      })
      
      ThinkingSphinx::Search.search_for_id(42, "an_index").should be_true
    end
    
    it "should return false if no records are returned" do
      ThinkingSphinx::Search.search_for_id(42, "an_index").should be_false
    end
  end
  
  describe "instance_from_result method" do
    before :each do
      Person.track_methods(:find)
    end

    it "should honour the :include option" do
      ellie = ThinkingSphinx::Search.search("Ellie Ford", :include => :contacts).first
      pending
      Person.should have_received(:find).with(ellie.id, :include => :contacts, :select => nil)
    end

    it "should honour the :select option" do
      ellie = ThinkingSphinx::Search.search("Ellie Ford", :select => "*").first
      pending
      Person.should have_received(:find).with(ellie.id, :include => nil, :select => "*")
    end

  end

  describe "instances_from_results method" do
    before :each do
      Person.track_methods(:find)
      
      @ellie_ids = Person.search_for_ids "Ellie"
    end
    
    it "should call a find on all ids for the class" do
      Person.search "Ellie"
      
      Person.should have_received(:find).with(
        :all,
        :conditions => {:id => @ellie_ids},
        :include    => nil,
        :select     => nil
      )
    end

    it "should honour the :include option" do
      Person.search "Ellie", :include => :contacts
      
      Person.should have_received(:find).with(
        :all,
        :conditions => {:id => @ellie_ids},
        :include    => :contacts,
        :select     => nil
      )
    end

    it "should honour the :select option" do
      Person.search "Ellie", :select => "*"
      
      Person.should have_received(:find).with(
        :all,
        :conditions => {:id => @ellie_ids},
        :include    => nil,
        :select     => "*"
      )
    end
  end
  
  describe "count method" do
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

    it "should return query total" do
      ThinkingSphinx::Search.count(42, "an_index").should == 50
    end
  end
  
  describe "search result" do
    before :each do
      @results = ThinkingSphinx::Search.search "nothing will match this"
    end
    
    it "should respond to previous_page" do
      @results.should respond_to(:previous_page)
    end
    
    it "should respond to next_page" do
      @results.should respond_to(:next_page)
    end
    
    it "should respond to current_page" do
      @results.should respond_to(:current_page)
    end
    
    it "should respond to total_pages" do
      @results.should respond_to(:total_pages)
    end
    
    it "should respond to total_entries" do
      @results.should respond_to(:total_entries)
    end
    
    it "should respond to offset" do
      @results.should respond_to(:offset)
    end
        
    it "should be a subclass of Array" do
      @results.should be_kind_of(Array)
    end
  end
  
  it "should not return results that have been deleted" do
    Alpha.search("one").should_not be_empty
    
    alpha = Alpha.find(:first, :conditions => {:name => "one"})
    alpha.destroy
    
    Alpha.search("one").should be_empty
  end
  
  it "should still return edited results using old data if there's no delta" do
    Alpha.search("two").should_not be_empty
    
    alpha = Alpha.find(:first, :conditions => {:name => "two"})
    alpha.update_attributes(:name => "twelve")
    
    Alpha.search("two").should_not be_empty
  end
  
  it "should not return edited results using old data if there's a delta" do
    Beta.search("two").should_not be_empty
    
    beta = Beta.find(:first, :conditions => {:name => "two"})
    beta.update_attributes(:name => "twelve")
    
    Beta.search("two").should be_empty
  end
end
