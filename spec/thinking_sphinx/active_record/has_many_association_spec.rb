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
    
    it "should add a filter for an aliased attribute into a normal search call" do
      @team = CricketTeam.new
      @team.stub!(:id => 1)

      Person.should_receive(:search).with do |query, options|
        options[:with][:team_id].should == @team.id
      end

      @team.people.search "test"
    end

    it "should define indexes for the reflection class" do
      Friendship.should_receive(:define_indexes)
      
      @person.friendships.search 'test'
    end
  end
  
  describe "facets method" do
    before :each do
      Friendship.stub!(:facets => true)

      @person = Person.find(:first)
      @index  = Friendship.sphinx_indexes.first
    end

    it "should raise an error if the required attribute doesn't exist" do
      @index.stub!(:attributes => [])

      lambda { @person.friendships.facets "test" }.should raise_error(RuntimeError)
    end

    it "should add a filter for the attribute into a normal facets call" do
      Friendship.should_receive(:facets) do |query, options|
        options[:with][:person_id].should == @person.id
      end

      @person.friendships.facets "test"
    end

    it "should add a filter for an aliased attribute into a normal facets call" do
      @team = CricketTeam.new
      @team.stub!(:id => 1)

      Person.should_receive(:facets).with do |query, options|
        options[:with][:team_id].should == @team.id
      end

      @team.people.facets "test"
    end

    it "should define indexes for the reflection class" do
      Friendship.should_receive(:define_indexes)

      @person.friendships.facets 'test'
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

    it "should add a filter for an aliased attribute into a normal search call" do
      @team = FootballTeam.new
      @team.stub!(:id => 1)

      Person.should_receive(:search).with do |query, options|
        options[:with][:football_team_id].should == @team.id
      end

      @team.people.search "test"
    end
  end
  
  describe "facets method for has_many :through" do
    before :each do
      Person.stub!(:facets => true)

      @person = Person.find(:first)
      @index  = Person.sphinx_indexes.first
    end

    it "should raise an error if the required attribute doesn't exist" do
      @index.stub!(:attributes => [])

      lambda { @person.friends.facets "test" }.should raise_error(RuntimeError)
    end

    it "should add a filter for the attribute into a normal facets call" do
      Person.should_receive(:facets).with do |query, options|
        options[:with][:friendly_ids].should == @person.id
      end

      @person.friends.facets "test"
    end

    it "should add a filter for an aliased attribute into a normal facets call" do
      @team = FootballTeam.new
      @team.stub!(:id => 1)

      Person.should_receive(:facets).with do |query, options|
        options[:with][:football_team_id].should == @team.id
      end

      @team.people.facets "test"
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
