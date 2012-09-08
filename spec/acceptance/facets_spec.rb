require 'acceptance/spec_helper'

describe 'Faceted searching', :live => true do
  it "provides facet breakdowns across marked integer attributes" do
    blue  = Colour.create! :name => 'blue'
    red   = Colour.create! :name => 'red'
    green = Colour.create! :name => 'green'

    Tee.create! :colour => blue
    Tee.create! :colour => blue
    Tee.create! :colour => red
    Tee.create! :colour => green
    Tee.create! :colour => green
    Tee.create! :colour => green
    index

    Tee.facets.to_hash[:colour_id].should == {
      blue.id => 2, red.id => 1, green.id => 3
    }
  end

  it "provides facet breakdowns across classes" do
    Tee.create!
    Tee.create!
    City.create!
    index

    ThinkingSphinx.facets.to_hash[:class].should == {
      'Tee' => 2, 'City' => 1
    }
  end

  it "handles field facets" do
    Book.create! :title => 'American Gods', :author => 'Neil Gaiman'
    Book.create! :title => 'Anansi Boys',   :author => 'Neil Gaiman'
    Book.create! :title => 'Snuff',         :author => 'Terry Pratchett'
    index

    Book.facets.to_hash[:author].should == {
      'Neil Gaiman' => 2, 'Terry Pratchett' => 1
    }
  end

  it "handles MVA facets" do
    pancakes = Tag.create! :name => 'pancakes'
    waffles  = Tag.create! :name => 'waffles'

    user = User.create!
    Tagging.create! :article => Article.create!(:user => user),
      :tag => pancakes
    Tagging.create! :article => Article.create!(:user => user),
      :tag => waffles

    user = User.create!
    Tagging.create! :article => Article.create!(:user => user),
      :tag => pancakes
    index

    User.facets.to_hash[:tag_ids].should == {
      pancakes.id => 2, waffles.id => 1
    }
  end
end
