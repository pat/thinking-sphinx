require 'acceptance/spec_helper'

describe 'Sphinx scopes', :live => true do
  it "allows calling sphinx scopes from models" do
    gods  = Book.create! :title => 'American Gods',      :year => 2001
    boys  = Book.create! :title => 'Anansi Boys',        :year => 2005
    grave = Book.create! :title => 'The Graveyard Book', :year => 2009
    index

    Book.by_year(2009).to_a.should == [grave]
  end
end
