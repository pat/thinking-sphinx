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

  it "sorts by a given sortable field with real-time indices" do
    widgets = Product.create! :name => 'Widgets'
    gadgets = Product.create! :name => 'Gadgets'

    Product.search(:order => "name_sort ASC").to_a.should == [gadgets, widgets]
  end

  it "can sort with a provided expression" do
    gods  = Book.create! :title => 'American Gods',      :year => 2001
    grave = Book.create! :title => 'The Graveyard Book', :year => 2009
    boys  = Book.create! :title => 'Anansi Boys',        :year => 2005
    index

    Book.search(
      :select => 'year MOD 2004 as mod_year', :order => 'mod_year ASC'
    ).to_a.should == [boys, grave, gods]
  end
end
