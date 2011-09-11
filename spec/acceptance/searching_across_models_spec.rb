require 'spec_helper'

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
end
