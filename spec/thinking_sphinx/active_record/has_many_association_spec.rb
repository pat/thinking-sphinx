require 'spec_helper'

describe 'ThinkingSphinx::ActiveRecord::HasManyAssociation' do
  describe "search method" do
    before :each do
      Friendship.stub!(:search => true)
      
      @person = Person.find(:first)
      @index  = Friendship.sphinx_indexes.first
    end
    
    it "should raise an error if the required attribute doesn't exist" do
      @index.stub!(:attributes => [])
      
      lambda { @person.friendships.search "test" }.should raise_error(RuntimeError)
    end
    
    it "should add a filter for the attribute into a normal search call" do
      Friendship.should_receive(:search) do |query, options|
        options[:with][:person_id].should == @person.id
      end
      
      @person.friendships.search "test"
    end
    
    it "should define indexes for the reflection class" do
      Friendship.should_receive(:define_indexes)
      
      @person.friendships.search 'test'
    end
  end
  
  describe "search method for has_many :through" do
    before :each do
      Person.stub!(:search => true)
      
      @person = Person.find(:first)
      @index  = Person.sphinx_indexes.first
    end
    
    it "should raise an error if the required attribute doesn't exist" do
      @index.stub!(:attributes => [])
      
      lambda { @person.friends.search "test" }.should raise_error(RuntimeError)
    end
    
    it "should add a filter for the attribute into a normal search call" do
      Person.should_receive(:search).with do |query, options|
        options[:with][:friendly_ids].should == @person.id
      end
      
      @person.friends.search "test"
    end
  end
  
  describe 'filtering sphinx scopes' do
    before :each do
      Friendship.stub!(:search => Friendship)
      
      @person = Person.find(:first)
    end
    
    it "should add a filter for the attribute in a sphinx scope call" do
      Friendship.should_receive(:search).with do |options|
        options[:with][:person_id].should == @person.id
        Friendship
      end
      
      @person.friendships.reverse
    end
  end
end
