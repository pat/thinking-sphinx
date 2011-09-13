require 'spec_helper'

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
end
