require 'acceptance/spec_helper'

describe 'Searching with filters', :live => true do
  it "limits results by single value boolean filters" do
    pancakes = Article.create! :title => 'Pancakes', :published => true
    waffles  = Article.create! :title => 'Waffles',  :published => false
    index

    expect(Article.search(:with => {:published => true}).to_a).to eq([pancakes])
  end

  it "limits results by an array of values" do
    gods  = Book.create! :title => 'American Gods',      :year => 2001
    boys  = Book.create! :title => 'Anansi Boys',        :year => 2005
    grave = Book.create! :title => 'The Graveyard Book', :year => 2009
    index

    expect(Book.search(:with => {:year => [2001, 2005]}).to_a).to eq([gods, boys])
  end

  it "limits results by a ranged filter" do
    gods  = Book.create! :title => 'American Gods'
    boys  = Book.create! :title => 'Anansi Boys'
    grave = Book.create! :title => 'The Graveyard Book'

    gods.update_column  :created_at, 5.days.ago
    boys.update_column  :created_at, 3.days.ago
    grave.update_column :created_at, 1.day.ago
    index

    expect(Book.search(:with => {:created_at => 6.days.ago..2.days.ago}).to_a).
      to eq([gods, boys])
  end

  it "limits results by exclusive filters on single values" do
    pancakes = Article.create! :title => 'Pancakes', :published => true
    waffles  = Article.create! :title => 'Waffles',  :published => false
    index

    expect(Article.search(:without => {:published => true}).to_a).to eq([waffles])
  end

  it "limits results by exclusive filters on arrays of values" do
    gods  = Book.create! :title => 'American Gods',      :year => 2001
    boys  = Book.create! :title => 'Anansi Boys',        :year => 2005
    grave = Book.create! :title => 'The Graveyard Book', :year => 2009
    index

    expect(Book.search(:without => {:year => [2001, 2005]}).to_a).to eq([grave])
  end

  it "limits results by ranged filters on timestamp MVAs" do
    pancakes = Article.create :title => 'Pancakes'
    waffles  = Article.create :title => 'Waffles'

    food = Tag.create :name => 'food'
    flat = Tag.create :name => 'flat'

    Tagging.create(:tag => food, :article => pancakes).
      update_column :created_at, 5.days.ago
    Tagging.create :tag => flat, :article => pancakes
    Tagging.create(:tag => food, :article => waffles).
      update_column :created_at, 3.days.ago

    index

    expect(Article.search(
      :with => {:taggings_at => 1.days.ago..1.day.from_now}
    ).to_a).to eq([pancakes])
  end

  it "takes into account local timezones for timestamps" do
    pancakes = Article.create :title => 'Pancakes'
    waffles  = Article.create :title => 'Waffles'

    food = Tag.create :name => 'food'
    flat = Tag.create :name => 'flat'

    Tagging.create(:tag => food, :article => pancakes).
      update_column :created_at, 5.minutes.ago
    Tagging.create :tag => flat, :article => pancakes
    Tagging.create(:tag => food, :article => waffles).
      update_column :created_at, 3.minute.ago

    index

    expect(Article.search(
      :with => {:taggings_at => 2.minutes.ago..Time.zone.now}
    ).to_a).to eq([pancakes])
  end

  it "limits results with MVAs having all of the given values" do
    pancakes = Article.create :title => 'Pancakes'
    waffles  = Article.create :title => 'Waffles'

    food = Tag.create :name => 'food'
    flat = Tag.create :name => 'flat'

    Tagging.create :tag => food, :article => pancakes
    Tagging.create :tag => flat, :article => pancakes
    Tagging.create :tag => food, :article => waffles

    index

    articles = Article.search :with_all => {:tag_ids => [food.id, flat.id]}
    expect(articles.to_a).to eq([pancakes])
  end

  it "limits results with MVAs that don't contain all the given values" do
    # Matching results may have some of the given values, but cannot have all
    # of them. Certainly an edge case.
    skip "SphinxQL doesn't yet support OR in its WHERE clause"

    pancakes = Article.create :title => 'Pancakes'
    waffles  = Article.create :title => 'Waffles'

    food = Tag.create :name => 'food'
    flat = Tag.create :name => 'flat'

    Tagging.create :tag => food, :article => pancakes
    Tagging.create :tag => flat, :article => pancakes
    Tagging.create :tag => food, :article => waffles

    index

    articles = Article.search :without_all => {:tag_ids => [food.id, flat.id]}
    expect(articles.to_a).to eq([waffles])
  end

  it "limits results on real-time indices with multi-value integer attributes" do
    pancakes = Product.create :name => 'Pancakes'
    waffles  = Product.create :name => 'Waffles'

    food = Category.create :name => 'food'
    flat = Category.create :name => 'flat'

    pancakes.categories << food
    pancakes.categories << flat
    waffles.categories  << food

    products = Product.search :with => {:category_ids => [flat.id]}
    expect(products.to_a).to eq([pancakes])
  end

  it 'searches with real-time JSON attributes' do
    pancakes = Product.create :name => 'Pancakes',
      :options => {'lemon' => 1, 'sugar' => 1, :number => 3}
    waffles  = Product.create :name => 'Waffles',
      :options => {'chocolate' => 1, 'sugar' => 1, :number => 1}

    products = Product.search :with => {"options.lemon" => 1}
    expect(products.to_a).to eq([pancakes])

    products = Product.search :with => {"options.sugar" => 1}
    expect(products.to_a).to eq([pancakes, waffles])
  end if JSONColumn.call
end
