require 'spec/spec_helper'
require 'will_paginate/collection'

describe ThinkingSphinx::Search do
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
      Person.stub_method(:find => true)
      ThinkingSphinx::Search.stub_method(:class_from_crc => Person)
    end
    
    after :each do
      Person.unstub_method(:find)
      ThinkingSphinx::Search.unstub_method(:class_from_crc)
    end

    it "should honour the :include option" do
      ThinkingSphinx::Search.send(
        :instance_from_result,
        {
          :doc => 1, :attributes => {
            "sphinx_internal_id" => 2, "class_crc" => 123
          }
        },
        {:include => :assoc}
      )

      Person.should have_received(:find).with(2, :include => :assoc, :select => nil)
    end

    it "should honour the :select option" do
      ThinkingSphinx::Search.send(
        :instance_from_result,
        {
          :doc => 1, :attributes => {
            "sphinx_internal_id" => 2, "class_crc" => 123
          }
        },
        {:select => :columns}
      )

      Person.should have_received(:find).with(2, :include => nil, :select => :columns)
    end

  end

  describe "instances_from_results method" do
    before :each do
      @person_a = Person.stub_instance
      @person_b = Person.stub_instance
      @person_c = Person.stub_instance

      @results = [
        {:attributes => {"sphinx_internal_id" => @person_a.id}},
        {:attributes => {"sphinx_internal_id" => @person_b.id}},
        {:attributes => {"sphinx_internal_id" => @person_c.id}}
      ]
      
      Person.stub_method(
        :find => [@person_c, @person_a, @person_b]
      )
      ThinkingSphinx::Search.stub_method(:instance_from_result => true)
    end

    after :each do
      Person.unstub_method(:find)
      ThinkingSphinx::Search.unstub_method(:instance_from_result)
    end

    it "should pass calls to instance_from_result if no class given" do
      ThinkingSphinx::Search.send(
        :instances_from_results, @results
      )

      ThinkingSphinx::Search.should have_received(:instance_from_result).with(
        {:attributes => {"sphinx_internal_id" => @person_a.id}}, {}
      )
      ThinkingSphinx::Search.should have_received(:instance_from_result).with(
        {:attributes => {"sphinx_internal_id" => @person_b.id}}, {}
      )
      ThinkingSphinx::Search.should have_received(:instance_from_result).with(
        {:attributes => {"sphinx_internal_id" => @person_c.id}}, {}
      )
    end

    it "should call a find on all ids for the class" do
      ThinkingSphinx::Search.send(
        :instances_from_results, @results, {}, Person
      )
      
      Person.should have_received(:find).with(
        :all,
        :conditions => {:id => [@person_a.id, @person_b.id, @person_c.id]},
        :include    => nil,
        :select     => nil
      )
    end

    it "should honour the :include option" do
      ThinkingSphinx::Search.send(
        :instances_from_results, @results, {:include => :something}, Person
      )
      
      Person.should have_received(:find).with(
        :all,
        :conditions => {:id => [@person_a.id, @person_b.id, @person_c.id]},
        :include    => :something,
        :select     => nil
      )
    end

    it "should honour the :select option" do
      ThinkingSphinx::Search.send(
        :instances_from_results, @results, {:select => :fields}, Person
      )
      
      Person.should have_received(:find).with(
        :all,
        :conditions => {:id => [@person_a.id, @person_b.id, @person_c.id]},
        :include    => nil,
        :select     => :fields
      )
    end

    it "should sort the objects the same as the result set" do
      ThinkingSphinx::Search.send(
        :instances_from_results, @results, {:select => :fields}, Person
      ).should == [@person_a, @person_b, @person_c]
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
end
