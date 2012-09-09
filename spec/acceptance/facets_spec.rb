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

  it "can filter on integer facet results" do
    blue  = Colour.create! :name => 'blue'
    red   = Colour.create! :name => 'red'

    b1 = Tee.create! :colour => blue
    b2 = Tee.create! :colour => blue
    r1 = Tee.create! :colour => red
    index

    Tee.facets.for(:colour_id => blue.id).to_a.should == [b1, b2]
  end

  it "can filter on MVA facet results" do
    pancakes = Tag.create! :name => 'pancakes'
    waffles  = Tag.create! :name => 'waffles'

    u1 = User.create!
    Tagging.create! :article => Article.create!(:user => u1), :tag => pancakes
    Tagging.create! :article => Article.create!(:user => u1), :tag => waffles

    u2 = User.create!
    Tagging.create! :article => Article.create!(:user => u2), :tag => pancakes
    index

    User.facets.for(:tag_ids => waffles.id).to_a.should == [u1]
  end

  it "can filter on string facet results" do
    gods  = Book.create! :title => 'American Gods', :author => 'Neil Gaiman'
    boys  = Book.create! :title => 'Anansi Boys', :author => 'Neil Gaiman'
    snuff = Book.create! :title => 'Snuff', :author => 'Terry Pratchett'
    index

    Book.facets.for(:author => 'Neil Gaiman').to_a.should == [gods, boys]
  end

  it "allows enumeration" do
    blue  = Colour.create! :name => 'blue'
    red   = Colour.create! :name => 'red'

    b1 = Tee.create! :colour => blue
    b2 = Tee.create! :colour => blue
    r1 = Tee.create! :colour => red
    index

    calls = 0
    expectations = [
      [:sphinx_internal_class, {'Tee' => 3}],
      [:colour_id, {blue.id => 2, red.id => 1}],
      [:class, {'Tee' => 3}]
    ]
    Tee.facets.each do |facet, hash|
      facet.should == expectations[calls].first
      hash.should == expectations[calls].last

      calls += 1
    end
  end
end
