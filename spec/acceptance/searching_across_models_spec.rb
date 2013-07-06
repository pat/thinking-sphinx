require 'acceptance/spec_helper'

describe 'Searching across models', :live => true do
  it "returns results" do
    article = Article.create! :title => 'Pancakes'
    index

    ThinkingSphinx.search.first.should == article
  end

  it "returns results matching the given query" do
    pancakes = Article.create! :title => 'Pancakes'
    waffles  = Article.create! :title => 'Waffles'
    index

    articles = ThinkingSphinx.search 'pancakes'
    articles.should include(pancakes)
    articles.should_not include(waffles)
  end

  it "handles results from different models" do
    article = Article.create! :title => 'Pancakes'
    book    = Book.create! :title => 'American Gods'
    index

    ThinkingSphinx.search.to_a.should =~ [article, book]
  end

  it "filters by multiple classes" do
    article = Article.create! :title => 'Pancakes'
    book    = Book.create! :title => 'American Gods'
    user    = User.create! :name => 'Pat'
    index

    ThinkingSphinx.search(:classes => [User, Article]).to_a.
      should =~ [article, user]
  end
end
