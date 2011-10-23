require 'acceptance/spec_helper'

describe 'Sorting search results', :live => true do
  it "sorts by a given clause" do
    gods  = Book.create! :title => 'American Gods',      :year => 2001
    grave = Book.create! :title => 'The Graveyard Book', :year => 2009
    boys  = Book.create! :title => 'Anansi Boys',        :year => 2005
    index

    Book.search(:order => 'year ASC').to_a.should == [gods, boys, grave]
  end

  it "sorts by a given attribute in ascending order" do
    gods  = Book.create! :title => 'American Gods',      :year => 2001
    grave = Book.create! :title => 'The Graveyard Book', :year => 2009
    boys  = Book.create! :title => 'Anansi Boys',        :year => 2005
    index

    Book.search(:order => :year).to_a.should == [gods, boys, grave]
  end

  it "sorts by a given sortable field" do
    gods  = Book.create! :title => 'American Gods',      :year => 2001
    grave = Book.create! :title => 'The Graveyard Book', :year => 2009
    boys  = Book.create! :title => 'Anansi Boys',        :year => 2005
    index

    Book.search(:order => :title).to_a.should == [gods, boys, grave]
  end
end
