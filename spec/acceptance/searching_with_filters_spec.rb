require 'acceptance/spec_helper'

describe 'Searching with filters', :live => true do
  it "limits results by single value boolean filters" do
    pancakes = Article.create! :title => 'Pancakes', :published => true
    waffles  = Article.create! :title => 'Waffles',  :published => false
    index

    Article.search(:with => {:published => true}).to_a.should == [pancakes]
  end

  it "limits results by an array of values" do
    gods  = Book.create! :title => 'American Gods',      :year => 2001
    boys  = Book.create! :title => 'Anansi Boys',        :year => 2005
    grave = Book.create! :title => 'The Graveyard Book', :year => 2009
    index

    Book.search(:with => {:year => [2001, 2005]}).to_a.should == [gods, boys]
  end

  it "limits results by a ranged filter" do
    gods  = Book.create! :title => 'American Gods'
    boys  = Book.create! :title => 'Anansi Boys'
    grave = Book.create! :title => 'The Graveyard Book'

    gods.update_attribute  :created_at, 5.days.ago
    boys.update_attribute  :created_at, 3.days.ago
    grave.update_attribute :created_at, 1.day.ago
    index

    Book.search(:with => {:created_at => 6.days.ago..2.days.ago}).to_a.
      should == [gods, boys]
  end

  it "limits results by exclusive filters on single values" do
    pancakes = Article.create! :title => 'Pancakes', :published => true
    waffles  = Article.create! :title => 'Waffles',  :published => false
    index

    Article.search(:without => {:published => true}).to_a.should == [waffles]
  end

  it "limits results by exclusive filters on arrays of values" do
    gods  = Book.create! :title => 'American Gods',      :year => 2001
    boys  = Book.create! :title => 'Anansi Boys',        :year => 2005
    grave = Book.create! :title => 'The Graveyard Book', :year => 2009
    index

    Book.search(:without => {:year => [2001, 2005]}).to_a.should == [grave]
  end
end
