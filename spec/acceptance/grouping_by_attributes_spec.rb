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

  it "allows enumerating by count" do
    snuff  = Book.create! :title => 'Snuff',          :year => 2011
    earth  = Book.create! :title => 'The Long Earth', :year => 2012
    dodger = Book.create! :title => 'Dodger',         :year => 2012

    index

    expectations = [[snuff, 1], [earth, 2]]

    Book.search(:group_by => :year).each_with_count do |book, count|
      expectation = expectations.shift

      book.should  == expectation.first
      count.should == expectation.last
    end
  end

  it "allows enumerating by group" do
    snuff  = Book.create! :title => 'Snuff',          :year => 2011
    earth  = Book.create! :title => 'The Long Earth', :year => 2012
    dodger = Book.create! :title => 'Dodger',         :year => 2012

    index

    expectations = [[snuff, 2011], [earth, 2012]]

    Book.search(:group_by => :year).each_with_group do |book, group|
      expectation = expectations.shift

      book.should  == expectation.first
      group.should == expectation.last
    end
  end

  it "allows enumerating by group and count" do
    snuff  = Book.create! :title => 'Snuff',          :year => 2011
    earth  = Book.create! :title => 'The Long Earth', :year => 2012
    dodger = Book.create! :title => 'Dodger',         :year => 2012

    index

    expectations = [[snuff, 2011, 1], [earth, 2012, 2]]
    search       = Book.search(:group_by => :year)

    search.each_with_group_and_count do |book, group, count|
      expectation = expectations.shift

      book.should  == expectation[0]
      group.should == expectation[1]
      count.should == expectation[2]
    end
  end
end
