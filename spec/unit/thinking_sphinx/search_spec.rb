require 'spec/spec_helper'

describe ThinkingSphinx::Search do
  describe "instance_from_result method" do
    before :each do
      class Person < ActiveRecord::Base
        #
      end
    end
    
    it "should honour the :include option" do
      Person.stub_method(:find => true)
      
      ThinkingSphinx::Search.send(
        :instance_from_result,
        {:doc => 1},
        {:include => :assoc},
        Person
      )
      
      Person.should have_received(:find).with(1, :include => :assoc, :select => nil)
    end
    
    it "should honour the :select option" do
      Person.stub_method(:find => true)
      
      ThinkingSphinx::Search.send(
        :instance_from_result,
        {:doc => 1},
        {:select => :columns},
        Person
      )
      
      Person.should have_received(:find).with(1, :include => nil, :select => :columns)
    end
    
  end
end