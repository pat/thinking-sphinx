require 'acceptance/spec_helper'

describe 'Grouping search results by attributes', :live => true do
  it "groups by the provided attribute" do
    snuff  = Book.create! :title => 'Snuff',          :year => 2011
    earth  = Book.create! :title => 'The Long Earth', :year => 2012
    dodger = Book.create! :title => 'Dodger',         :year => 2012

    index

    Book.search(:group_by => :year).to_a.should == [snuff, earth]
  end

  it "allows sorting within the group" do
    snuff  = Book.create! :title => 'Snuff',          :year => 2011
    earth  = Book.create! :title => 'The Long Earth', :year => 2012
    dodger = Book.create! :title => 'Dodger',         :year => 2012

    index

    Book.search(:group_by => :year, :order_group_by => 'title ASC').to_a.
      should == [snuff, dodger]
  end
end
